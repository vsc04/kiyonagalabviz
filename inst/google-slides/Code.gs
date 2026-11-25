/** Private API executable for kiyonagalabviz. No web app or public images. */
function kiyonagaSlides(request) {
  const lock = LockService.getScriptLock();
  lock.waitLock(30000);
  try {
    const deck = SlidesApp.openById(request.presentation);
    const metadata = Slides.Presentations.get(request.presentation);
    const properties = PropertiesService.getScriptProperties();
    const images = [];
    deck.getSlides().forEach((slide, index) => {
      slide.getImages().forEach(image => {
        const element = metadata.slides[index].pageElements.find(
          x => x.objectId === image.getObjectId());
        if (!element || !element.image) throw new Error('Cannot read panel metadata.');
        const key = request.presentation + ':' + image.getObjectId();
        const saved = properties.getProperty(key);
        const base = saved ? JSON.parse(saved) : [0, 0, 1, 1];
        const crop = (element.image.imageProperties || {}).cropProperties || {};
        images.push({image, key, base, rawCrop: crop, panel: image.getTitle() || '',
          object_id: image.getObjectId(), slide: index + 1,
          width: image.getWidth(), height: image.getHeight()});
      });
    });
    if (request.action === 'inspect') {
      const names = request.payload.panels || [];
      const selected = names.length ? names.map(name => {
        const matches = images.filter(x => x.panel === name);
        if (matches.length !== 1) throw new Error(
          'Panel "' + name + '" must match exactly one top-level image Alt text Title.');
        return matches[0];
      }) : images;
      return {panels: selected.map(x => ({panel: x.panel, object_id: x.object_id,
        slide: x.slide, width: x.width, height: x.height,
        crop: names.length ? kiyonagaCrop_(x.base, x.rawCrop) : null,
        fingerprint: kiyonagaFingerprint_(x)}))};
    }
    if (request.action !== 'update') throw new Error('Unknown Slides action.');
    const payload = request.payload;
    const found = images.filter(x => x.object_id === payload.object_id && x.panel === payload.panel);
    if (found.length !== 1) throw new Error('Panel was removed or renamed. Run refresh again.');
    const item = found[0];
    if (payload.fingerprint !== kiyonagaFingerprint_(item)) {
      throw new Error('Panel layout changed during refresh. Run refresh again.');
    }
    const crop = kiyonagaCrop_(item.base, item.rawCrop);
    if (JSON.stringify(crop) !== JSON.stringify(payload.crop)) throw new Error('Crop plan changed.');
    const image = item.image;
    const frame = {left: image.getLeft(), top: image.getTop(), rotation: image.getRotation(),
      width: image.getWidth(), height: image.getHeight(),
      title: image.getTitle(), description: image.getDescription()};
    const blob = Utilities.newBlob(Utilities.base64Decode(payload.image), 'image/png', payload.panel + '.png');
    // Replacement keeps the same element and stacking order. Restore its frame
    // explicitly because aspect-ratio fitting can otherwise change its size.
    const updated = image.replace(blob);
    properties.setProperty(item.key, JSON.stringify(crop));
    updated.setWidth(frame.width).setHeight(frame.height).setRotation(frame.rotation)
      .setLeft(frame.left).setTop(frame.top).setTitle(frame.title).setDescription(frame.description);
    deck.saveAndClose();
    return {panel: payload.panel, object_id: updated.getObjectId()};
  } finally {
    lock.releaseLock();
  }
}

function kiyonagaCrop_(base, crop) {
  const left = crop.leftOffset || 0;
  const top = crop.topOffset || 0;
  const right = 1 - (crop.rightOffset || 0);
  const bottom = 1 - (crop.bottomOffset || 0);
  if (Math.abs(crop.angle || 0) > 1e-10 || left < 0 || top < 0 || right > 1 ||
      bottom > 1 || left >= right || top >= bottom) {
    throw new Error('Unsupported crop: use an unrotated crop within the source image.');
  }
  const width = base[2] - base[0], height = base[3] - base[1];
  return [base[0] + width * left, base[1] + height * top,
    base[0] + width * right, base[1] + height * bottom]
    .map(x => Math.round(x * 1e12) / 1e12);
}

function kiyonagaFingerprint_(item) {
  const image = item.image, crop = item.rawCrop;
  return JSON.stringify([item.object_id, item.panel, image.getLeft(), image.getTop(),
    image.getWidth(), image.getHeight(), image.getRotation(),
    crop.leftOffset || 0, crop.topOffset || 0, crop.rightOffset || 0,
    crop.bottomOffset || 0, crop.angle || 0, item.base]);
}
