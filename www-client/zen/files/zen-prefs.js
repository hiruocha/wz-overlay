/* Default preferences for the Gentoo built www-client/zen */

// Use LANG environment variable to choose locale.
pref("intl.locale.requested", "");

// Avoid first-run default browser noise on managed systems.
pref("browser.shell.checkDefaultBrowser", false);

// Don't disable extensions shipped in application directories.
pref("extensions.autoDisableScopes", 11);
