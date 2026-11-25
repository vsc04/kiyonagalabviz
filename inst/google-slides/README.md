# Google Slides panel refresh

Arrange PNG panels in Slides, then refresh them from R while retaining their
positions, sizes and crops. Use Google sign-in; no API key is needed.

## For collaborators

**You do not need to create a Cloud project, OAuth client or Apps Script bridge.**
The maintainer does that once for the shared app. Ask them to enable access for
your Google account and provide the Desktop client JSON and deployment ID.
You also need edit access to your presentation.

1. Install the package and optional dependencies in **R** (`>` prompt):

   ```r
   install.packages("remotes")
   remotes::install_github("vsc04/kiyonagalabviz")
   install.packages(c("httr", "jsonlite", "png"))
   ```

   The maintainer must publish the feature first. If it is still on the feature
   branch, add `ref = "feature/google-slides-layout"` to `install_github()`.

2. Save the supplied JSON outside the repository as
   `~/.config/kiyonagalabviz/google_client.json`. On a Mac, create/open this
   folder in **Terminal**, then move the file there:

   ```bash
   mkdir -p "$HOME/.config/kiyonagalabviz"
   open "$HOME/.config/kiyonagalabviz"
   ```

3. Connect in **R**, signing in with **your own Google account**:

   ```r
   library(kiyonagalabviz)
   slides_auth(client = "~/.config/kiyonagalabviz/google_client.json")
   target <- slides_target("YOUR_GOOGLE_SLIDES_URL", "SHARED_DEPLOYMENT_ID")
   slides_panels(target)
   ```

Each person keeps their own token locally; never share a cached token. In each
new R session, repeat step 3. Continue with [Test one panel](#test-one-panel);
skip all maintainer setup below.


## Test one panel

Save a PNG in R:

```r
set.seed(1)
example_data <- data.frame(time = seq(0, 10, length.out = 40))
example_data$value <- 2 + 0.5 * example_data$time + rnorm(40, sd = 0.7)
p <- plot_scatter(example_data, "time", "value", fit = TRUE) +
  ggplot2::labs(title = "Original panel", x = "Time", y = "Value")
nice_save("panel_A.png", p, custom = c(4, 3), dpi = 150)
normalizePath("panel_A.png")
```

In Slides, choose **Insert → Image → Upload from computer** and select that PNG.
Open its **Alt text** settings and set **Title** to `panel_A` (look under
**Advanced options** if hidden). Arrange or crop the image; leave it ungrouped.

Then run in R:

```r
slides_panels(target)  # should include panel_A
p <- p + ggplot2::labs(title = "Updated from R")
nice_save("panel_A.png", p, custom = c(4, 3), dpi = 150,
          slides = target, panel = "panel_A")
```

The title should update in Slides while the frame and crop remain in place.
Subsequent saves with `slides` and `panel` trigger updates. To refresh several
regenerated files together:

```r
slides_sync(target, c(panel_A = "panel_A.png", panel_B = "panel_B.png"))
```

## Troubleshooting

| Error | Fix |
|---|---|
| Credential file not found | Run `list.files("~/.config/kiyonagalabviz", full.names = TRUE)` in R and use the exact filename. |
| `ACCESS_TOKEN_SCOPE_INSUFFICIENT` | Confirm both scopes from step 2 are in Data Access and the bridge manifest. Deploy a new version, then force fresh consent below. |
| `SERVICE_DISABLED` | Open the enable link in the error and click **Enable** for that project. Wait a few minutes, then retry `slides_panels(target)`. No new sign-in is needed. |
| `The caller does not have permission` | Ask the maintainer to check the shared deployment's access and your test-user entry. The shared Desktop client and bridge must use the same Cloud project. |

After changing permissions or if a cached grant expires:

```r
slides_auth(client = "~/.config/kiyonagalabviz/google_client.json", reauth = TRUE)
```

## Usage notes

- Panel Titles must be unique. Updates require the R calls above; there is no
  background file watcher.
- Keep source dimensions and margins consistent. To reset a remembered crop,
  delete and reinsert the full PNG, then restore its Title. Rotated, flipped and
  out-of-bounds crop regions are unsupported.
- Keep SVG/PDF exports for vector publication output; Slides uses PNG previews.
  PNGs must be under 50 MB and at most 25 megapixels; lower `dpi` if necessary.
- A failed update can leave earlier panels updated. Inspect before retrying.
  Image effects such as shadows and recolouring are not preserved.


## One-time setup

Only the person maintaining the shared app completes these steps. Collaborators
reuse this setup and sign in individually.

### 1. Select a Cloud project and enable both APIs

Open [Google Cloud Console](https://console.cloud.google.com/welcome). Choose
one project in the top-bar project selector, or create one. Use the same project
throughout setup. Its name may differ from the app name you enter later.

Go to **APIs & Services → Library** and enable each API separately:

- **Google Apps Script API** (`script.googleapis.com`)
- **Google Slides API** (`slides.googleapis.com`)

Enabling one does **not** enable the other. Open each API's page and click
**Enable**; a **Disable API** button confirms only that specific API is enabled.

Return to the [Welcome page](https://console.cloud.google.com/welcome) and copy
the **Project number** below the heading. This is digits only, not the project ID.

### 2. Configure sign-in and both permissions

Go to **Google Auth Platform → Branding → Get Started**. Enter the app name
`kiyonagalabviz`, your support/contact email, and choose **External** for a
personal test app. Complete the prompts and click **Create**.

- **Audience → Test users → Add users:** add your Google email and each
  collaborator's Google email; keep **Testing** for lab testing.
- **Data Access → Add or remove scopes:** add both scopes below (use **Manually
  add scopes** if needed), then **Update → Save**.

```text
https://www.googleapis.com/auth/presentations
https://www.googleapis.com/auth/script.storage
```

### 3. Download the credentials

Go to **Google Auth Platform → Clients → Create client → Desktop app**.
Name it `kiyonagalabviz`, click **Create**, then **Download JSON**. The Clients
list is empty until you create a client.

In **Terminal**, create and open the storage folder:

```bash
mkdir -p "$HOME/.config/kiyonagalabviz"
open "$HOME/.config/kiyonagalabviz"
```

Move the JSON there and rename it exactly **`google_client.json`** (underscore).
Keep it outside the repository. Tokens default to your user cache outside the
repository too; never commit credentials or tokens.

### 4. Create the Apps Script bridge

Open [Apps Script](https://script.google.com/) → **New project**.

1. Replace the default `Code.gs` contents with [Code.gs](Code.gs) from this folder.
2. Under **Project Settings** (gear), enable **Show appsscript.json manifest file
   in editor**. Return to the editor, replace that manifest with our
   [appsscript.json](appsscript.json), and save.
3. Under **Project Settings → Google Cloud Platform Project → Change project**,
   enter the **project number from step 1**. It must match the Desktop client's
   Cloud project.
4. Choose **Deploy → New deployment → Select type → API executable**. The
   bundled manifest defaults to **Only myself** for initial testing. For the
   shared lab app, change `executionApi` in the manifest to
   `{"access": "ANYONE"}`, then deploy with access for signed-in Google users.
   Do not choose anonymous access. For a lab entirely within one Google
   Workspace organization, `DOMAIN` is another option. Copy the **Deployment ID**.

Provide collaborators with the Desktop client JSON and deployment ID through
your lab's private sharing channel. Do not share your token. Everyone uses the
same OAuth client and bridge Cloud project, but authenticates as themselves.
Changing access in the manifest requires deploying a new version too.

For later bridge changes: **Deploy → Manage deployments → pencil icon → Version:
New version → Deploy**. This keeps your deployment ID.

### 5. Test the maintainer connection

Run this at the **R prompt (`>`)**, from the package directory. If Terminal shows
`%`, first run `conda activate vae-r`, then `R`. If R cannot be found, use
`/Users/zhuojunying/miniforge3/envs/vae-r/bin/R`.

```r
install.packages(c("httr", "jsonlite", "png"))
devtools::load_all(".")
slides_auth(client = "~/.config/kiyonagalabviz/google_client.json")

target <- slides_target(
  presentation = "PASTE_YOUR_GOOGLE_SLIDES_URL",
  deployment_id = "PASTE_YOUR_API_EXECUTABLE_DEPLOYMENT_ID"
)
slides_panels(target)
```

Approve the permissions in the browser. `slides_panels()` lists images without
changing them; an empty result is normal for a blank presentation. Install the
packages only once; repeat the other calls in each new R session.
