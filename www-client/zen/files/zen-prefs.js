/* Default preferences for the Gentoo built www-client/zen */

// Use LANG environment variable to choose locale.
pref("intl.locale.requested", "");

// Avoid first-run default browser noise on managed systems.
pref("browser.shell.checkDefaultBrowser", false);

// Don't disable extensions shipped in application directories.
pref("extensions.autoDisableScopes", 11);

// The language packs built by this ebuild are unsigned (Firefox's browser
// default requires Mozilla signatures); allow them so the language picker
// can offer them, like the official builds' bundled locales.
pref("extensions.langpacks.signatures.required", false);
