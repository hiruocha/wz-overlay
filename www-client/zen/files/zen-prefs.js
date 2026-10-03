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

// Gentoo's Safe Browsing API key has no Safe Browsing v5 access (v5
// requests get a bare 404 from the API frontend), while Firefox prefers
// v5 for every table that exists in both protocols -- which would leave
// all Google tables without updates.  Fall back to the v4 provider,
// which works with this key (re-enable the pref to use v5 with a key
// that supports it).
pref("browser.safebrowsing.provider.google5.enabled", false);
