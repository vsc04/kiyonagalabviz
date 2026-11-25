// Run with node tools/test_google_slides.mjs. No Google account or credentials.
import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const source = fs.readFileSync(new URL('../inst/google-slides/Code.gs', import.meta.url), 'utf8');
const plain = x => JSON.parse(JSON.stringify(x));

function harness() {
  const state = new Map();
  const image = {id: 'image_A', title: 'panel_A', description: 'Panel description',
    left: 20, top: 30, width: 200, height: 150, rotation: 15, crop: {}, writes: 0};
  for (const name of ['Title', 'Description', 'Left', 'Top', 'Width', 'Height', 'Rotation']) {
    const key = name[0].toLowerCase() + name.slice(1);
    image['get' + name] = () => image[key];
    image['set' + name] = value => { image[key] = value; return image; };
  }
  image.getObjectId = () => image.id;
  image.replace = () => {
    image.writes++;
    image.width = 500;
    image.height = 300;
    image.title = '';
    image.description = '';
    image.crop = {};
    return image;
  };
  const images = [image];
  const deck = {getSlides: () => [{getImages: () => images}], saveAndClose() {}};
  const context = vm.createContext({
    SlidesApp: {openById: () => deck},
    Slides: {Presentations: {get: () => ({slides: [{pageElements: images.map(x => ({
      objectId: x.id, image: {imageProperties: {cropProperties: x.crop}}
    }))}]})}},
    PropertiesService: {getScriptProperties: () => ({
      getProperty: key => state.get(key),
      setProperty: (key, value) => state.set(key, value)
    })},
    LockService: {getScriptLock: () => ({waitLock() {}, releaseLock() {}})},
    Utilities: {base64Decode: x => Buffer.from(x, 'base64'), newBlob: x => x}
  });
  vm.runInContext(source, context);
  const call = (action, payload) => context.kiyonagaSlides({presentation: 'deck', action, payload});
  const inspect = () => plain(call('inspect', {panels: ['panel_A']})).panels[0];
  const update = plan => call('update', {...plan, image: 'UE5H'});
  return {image, images, call, inspect, update};
}

{
  const h = harness();
  h.image.crop = {leftOffset: .2, rightOffset: .1, topOffset: .1, bottomOffset: .2};
  const first = h.inspect();
  assert.deepEqual(first.crop, [.2, .1, .9, .8]);
  h.update(first);
  assert.deepEqual([h.image.left, h.image.top, h.image.width, h.image.height, h.image.rotation],
    [20, 30, 200, 150, 15]);
  assert.equal(h.image.title, 'panel_A');
  assert.equal(h.image.description, 'Panel description');
  assert.deepEqual(h.inspect().crop, first.crop);
  h.update(h.inspect());
  assert.deepEqual(h.inspect().crop, first.crop);
  h.image.crop = {leftOffset: .25, rightOffset: .25};
  const recropped = h.inspect();
  assert.deepEqual(recropped.crop, [.375, .1, .725, .8]);
  h.update(recropped);
  assert.deepEqual(h.inspect().crop, recropped.crop);
  assert.equal(h.image.writes, 3);
}
{
  const h = harness();
  const plan = h.inspect();
  h.image.left++;
  assert.throws(() => h.update(plan), /layout changed/);
  assert.equal(h.image.writes, 0);
  h.image.title = 'renamed';
  assert.throws(() => h.update(plan), /removed or renamed/);
  assert.throws(() => h.inspect(), /exactly one/);
}
{
  const h = harness();
  h.images.push(h.image);
  assert.throws(() => h.inspect(), /exactly one/);
  assert.equal(h.image.writes, 0);
}
for (const crop of [{angle: .1}, {leftOffset: -.1}, {leftOffset: .8, rightOffset: .4}]) {
  const h = harness();
  h.image.crop = crop;
  assert.throws(() => h.inspect(), /Unsupported crop/);
  assert.equal(h.image.writes, 0);
}
console.log('Google Slides bridge tests passed');
