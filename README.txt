SHARDBOUND - iPhone home-screen app (no Mac needed)

These files must be hosted on a website (https) before your iPhone can install them.
Free option: GitHub Pages. Do steps 1-4 on your Windows PC.

1. Sign in at github.com (create a free account if needed).
2. Click "+" (top right) > New repository. Name it "shardbound".
   Set it to Public, then click "Create repository".
3. On the new repo page click "uploading an existing file".
   Drag in ALL the files from this folder (index.html, sw.js,
   manifest.webmanifest and the icon PNGs). Click "Commit changes".
4. Go to Settings > Pages. Under "Branch" choose "main" and "/ (root)",
   then click Save. After a minute or two the page shows your site address:
   https://YOUR-USERNAME.github.io/shardbound/

On your iPhone:
5. Open that address in Safari (it must be Safari).
6. Tap the Share button (square with an up arrow), then "Add to Home Screen", then "Add".
7. Launch Shardbound from its home-screen icon. It runs full-screen. After the first
   launch it also works offline.

Updating the game later: upload the new index.html to the repo, and change
VERSION in sw.js (for example shardbound-v2). Close and reopen the app twice
to pick up the update.

Note: progress is saved on the phone. The home-screen app keeps its own save,
separate from the Safari tab.
