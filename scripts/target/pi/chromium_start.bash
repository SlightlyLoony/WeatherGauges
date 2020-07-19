# This script is executed by the chromium service.


  # make certain we have a display defined...
  export DISPLAY=:0

  # start chromium in the background...
  nohup chromium-browser                    `# the actual app`                                        \
    --noerrdialogs                          `# don't pop up any sort of error dialog`                 \
    --disable-component-update              `# don't check for updates`                               \
    --check-for-update-interval=1576800000  `# 50 year update check interval`                         \
    --kiosk                                 `# kiosk mode, no menus, toolbar, etc.`                   \
    --no-default-browser-check              `# don't check to see if chromium is the default browser` \
    --app=http://localhost:8888/kiosk.html  `# launch our app`                                        \
    &>/home/pi/chromium.out
