{ stdenv, lib, callPackage, fetchurl, fetchpatch, nixosTests }:

let
  common = opts: callPackage (import ./common.nix opts) {};
in

rec {
  firefox = common rec {
    pname = "firefox";
    version = "98.0";
    src = fetchurl {
      url = "mirror://mozilla/firefox/releases/${version}/source/firefox-${version}.source.tar.xz";
      sha512 = "5b9186dd2a5dee5f2d2a2ce156fc06e2073cf71a70891a294cf3358218592f19ec3413d33b68d6f38e3cc5f940213e590a188e2b6efc39f416e90a55f89bfd9b";
    };

    meta = {
      description = "A web browser built from Firefox source tree";
      homepage = "http://www.mozilla.com/en-US/firefox/";
      maintainers = with lib.maintainers; [ lovesegfault hexa ];
      platforms = lib.platforms.unix;
      badPlatforms = lib.platforms.darwin;
      broken = stdenv.buildPlatform.is32bit; # since Firefox 60, build on 32-bit platforms fails with "out of memory".
                                             # not in `badPlatforms` because cross-compilation on 64-bit machine might work.
      maxSilent = 14400; # 4h, double the default of 7200s (c.f. #129212, #129115)
      license = lib.licenses.mpl20;
    };
    tests = [ nixosTests.firefox ];
    updateScript = callPackage ./update.nix {
      attrPath = "firefox-unwrapped";
    };
  };

  firefox-esr-91 = common rec {
    pname = "firefox-esr";
    version = "91.7.0esr";
    src = fetchurl {
      url = "mirror://mozilla/firefox/releases/${version}/source/firefox-${version}.source.tar.xz";
      sha512 = "925811989d8a91d826ba356bd46ac54be8153288ec0319c28d2bfbe89191e62e107691159dd7ca247253e2a4952eb59a5b9613e3feea3f5351238d4822e26301";
    };

    meta = {
      description = "A web browser built from Firefox Extended Support Release source tree";
      homepage = "http://www.mozilla.com/en-US/firefox/";
      maintainers = with lib.maintainers; [ hexa ];
      platforms = lib.platforms.unix;
      badPlatforms = lib.platforms.darwin;
      broken = stdenv.buildPlatform.is32bit; # since Firefox 60, build on 32-bit platforms fails with "out of memory".
                                             # not in `badPlatforms` because cross-compilation on 64-bit machine might work.
      license = lib.licenses.mpl20;
    };
    tests = [ nixosTests.firefox-esr-91 ];
    updateScript = callPackage ./update.nix {
      attrPath = "firefox-esr-91-unwrapped";
      versionSuffix = "esr";
    };
  };

  librewolf =
  let
    librewolf-src = callPackage ./librewolf { };
  in
  (common rec {
    pname = "librewolf";
    binaryName = "librewolf";
    version = librewolf-src.packageVersion;
    src = librewolf-src.firefox;
    inherit (librewolf-src) extraConfigureFlags extraPostPatch extraPassthru;

    meta = {
      description = "A fork of Firefox, focused on privacy, security and freedom";
      homepage = "https://librewolf.net/";
      maintainers = with lib.maintainers; [ squalus ];
      inherit (firefox.meta) platforms badPlatforms broken maxSilent license;
    };
    updateScript = callPackage ./librewolf/update.nix {
      attrPath = "librewolf-unwrapped";
    };
  }).override {
    crashreporterSupport = false;
    enableOfficialBranding = false;
  };
}
