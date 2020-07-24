/** Firefox tweaks for postmarketOS **/

// Select a mobile user agent for firefox (same as tor browser on android)
pref('general.useragent.override', 'Mozilla/5.0 (Android 6.0; Mobile; rv:68.0) Gecko/20100101 Firefox/68.0');

// Enable android-style pinch-to-zoom
pref('dom.w3c.touch_events.enabled', true);
pref('apz.allow_zooming', true);
pref('apz.allow_double_tap_zooming', true);

// Move all buttons to the overflow menu and remove spacers around the address bar
pref("browser.uiCustomization.state", "{\"placements\":{\"widget-overflow-fixed-list\":[\"stop-reload-button\",\"home-button\",\"library-button\",\"fxa-toolbar-menu-button\",\"sidebar-button\",\"downloads-button\"],\"nav-bar\":[\"back-button\",\"forward-button\",\"urlbar-container\"],\"toolbar-menubar\":[\"menubar-items\"],\"TabsToolbar\":[\"tabbrowser-tabs\",\"new-tab-button\",\"alltabs-button\"],\"PersonalToolbar\":[\"personal-bookmarks\"]},\"seen\":[\"developer-button\"],\"dirtyAreaCache\":[\"nav-bar\",\"toolbar-menubar\",\"TabsToolbar\",\"PersonalToolbar\",\"widget-overflow-fixed-list\"],\"currentVersion\":16,\"newElementCount\":4}");

// Disable search suggestions
pref('browser.search.suggest.enabled', false);

// Empty new tab page: faster, less distractions
pref('browser.newtabpage.enabled', false);
