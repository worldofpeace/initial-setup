// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2017 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace LocaleHelper {
    [DBus (name = "org.freedesktop.locale1")]
    interface Locale1 : Object {
        [DBus (name = "SetLocale")]
        public abstract void set_locale (string[] locale, bool user_interaction) throws GLib.Error;
        [DBus (name = "SetVConsoleKeyboard")]
        public abstract void set_vconsole_keyboard (string keymap, string keymap_toggle, bool convert, bool user_interaction) throws GLib.Error;
        [DBus (name = "SetX11Keyboard")]
        public abstract void set_x11_keyboard (string layout, string model, string variant, string options, bool convert, bool user_interaction) throws GLib.Error;
        [DBus (name = "Locale")]
        public abstract string[] locale { owned get; }
        [DBus (name = "VConsoleKeymap")]
        public abstract string vconsole_keymap { owned get; }
        [DBus (name = "VConsoleKeymapToggle")]
        public abstract string vconsole_keymap_toggle { owned get; }
        [DBus (name = "X11Layout")]
        public abstract string x11_layout { owned get; }
        [DBus (name = "X11Model")]
        public abstract string x11_model { owned get; }
        [DBus (name = "X11Variant")]
        public abstract string x11_variant { owned get; }
        [DBus (name = "X11Options")]
        public abstract string x11_options { owned get; }
    }

    public class LangEntry {
        public string alpha_3;
        public string? alpha_2;
        public string name;
        public CountryEntry[] countries;

        public LangEntry () {
            countries = {};
        }

        public unowned string get_code () {
            return alpha_2 ?? alpha_3;
        }

        public void add_country (CountryEntry country_entry) {
            country_entry.lang = this;
            var _countries = countries;
            _countries += country_entry;
            countries = _countries;
        }
    }

    public struct CountryEntry {
        public string alpha_2;
        public string alpha_3;
        public string name;
        public unowned LangEntry lang;

        public unowned string get_code () {
            return alpha_2 ?? alpha_3;
        }

        public string get_full_code () {
            return "%s_%s".printf (lang.get_code (), get_code ());
        }
    }

    private static Gee.HashMap<string, LangEntry?> lang_entries;
    private static GLib.Mutex lang_mutex;

    public static Gee.HashMap<string, LangEntry?> get_lang_entries () {
        if (lang_entries == null) {
            lang_mutex = Mutex ();
            lang_entries = new Gee.HashMap<string, LangEntry?> ();
            var langs = Build.LANG_LIST.split (";");

            var parser = new Json.Parser ();
            try {
                parser.load_from_file ("/usr/share/iso-codes/json/iso_639-3.json");
                weak Json.Object root_object = parser.get_root ().get_object ();
                weak Json.Array 639_3_array = root_object.get_array_member ("639-3");
                foreach (unowned Json.Node element in 639_3_array.get_elements ()) {
                    weak Json.Object object = element.get_object ();
                    var entry = new LangEntry ();
                    entry.alpha_3 = object.get_string_member ("alpha_3");
                    if (object.has_member ("alpha_2")) {
                        entry.alpha_2 = object.get_string_member ("alpha_2");
                    }

                    var key_string = entry.get_code ();
                    entry.name = object.get_string_member ("name");
                    if (key_string in langs) {
                        lang_entries[key_string] = entry;
                    }
                }
            } catch (Error e) {
                critical (e.message);
            }

            var countries = new Gee.HashMap<string, CountryEntry?> ();
            parser = new Json.Parser ();
            try {
                parser.load_from_file ("/usr/share/iso-codes/json/iso_3166-1.json");
                weak Json.Object root_object = parser.get_root ().get_object ();
                weak Json.Array 639_3_array = root_object.get_array_member ("3166-1");
                foreach (unowned Json.Node element in 639_3_array.get_elements ()) {
                    weak Json.Object object = element.get_object ();
                    var entry = CountryEntry ();
                    entry.alpha_3 = object.get_string_member ("alpha_3");
                    entry.alpha_2 = object.get_string_member ("alpha_2");
                    entry.name = object.get_string_member ("name");
                    countries[entry.alpha_2] = entry;
                }
            } catch (Error e) {
                critical (e.message);
            }

            foreach (var lang in langs) {
                if (!("_" in lang)) {
                    continue;
                }

                var parts = lang.split ("_", 2);
                var lang_entry = lang_entries[parts[0]];
                var country = countries[parts[1]];
                if (country != null && lang_entry != null) {
                    lang_entry.add_country (country);
                }
            }

            // Now translate the labels in their original language.
            foreach (var lang_entry in lang_entries.values) {
                var lang_code = lang_entry.get_code ();
                lang_entry.name = lang_gettext (lang_entry.name, lang_code, "iso_639_3");
                if (lang_entry.countries.length > 0) {
                    lang_entry.name = _("%s…").printf (lang_entry.name);
                }

                foreach (var country in lang_entry.countries) {
                    country.name = lang_gettext (country.name, lang_code + "_" + country.alpha_2, "iso_3166");
                }
            }
        }

        return lang_entries;
    }

    // Taken from the /usr/share/language-tools/main-countries script.
    public static string? get_main_country (string lang_prefix) {
        switch (lang_prefix) {
            case "aa":
                return "ET";
            case "ar":
                return "EG";
            case "bn":
                return "BD";
            case "ca":
                return "ES";
            case "de":
                return "DE";
            case "el":
                return "GR";
            case "en":
                return "US";
            case "es":
                return "ES";
            case "eu":
                return "ES";
            case "fr":
                return "FR";
            case "fy":
                return "NL";
            case "it":
                return "IT";
            case "li":
                return "NL";
            case "nl":
                return "NL";
            case "om":
                return "ET";
            case "pa":
                return "PK";
            case "pt":
                return "PT";
            case "ru":
                return "RU";
            case "so":
                return "SO";
            case "sr":
                return "RS";
            case "sv":
                return "SE";
            case "ti":
                return "ER";
            case "tr":
                return "TR";
        }

        // We fallback to whatever is available in the lang list.
        var lang_prefixed = lang_prefix + "_";
        if (lang_prefixed in Build.LANG_LIST) {
            var parts = Build.LANG_LIST.split (lang_prefixed, 2);
            var country_part = parts[1].split (";", 2);
            return country_part[0];
        }

        return null;
    }

    /*
     * Always use this function to translate into another language to make sure
     * that no race occurs when switchbing the environment variable.
     */
    public unowned string lang_gettext (string source, string lang, string? domain = null) {
        lang_mutex.lock ();
        unowned string translation;
        var current_lang = GLib.Environment.get_variable ("LANGUAGE");
        GLib.Environment.set_variable ("LANGUAGE", lang, true);

        if (domain == null) {
            Intl.textdomain (Build.GETTEXT_PACKAGE);
            translation = _(source);
        } else {
            translation = dgettext (domain, source);
        }

        if (current_lang != null) {
            GLib.Environment.set_variable ("LANGUAGE", current_lang, true);
        } else {
            GLib.Environment.unset_variable ("LANGUAGE");
        }

        Intl.textdomain (Build.GETTEXT_PACKAGE);
        lang_mutex.unlock ();

        return translation;
    }
}
