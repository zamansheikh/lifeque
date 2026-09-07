import '../../../../../l10n/app_localizations.dart';

/// The ready-made wishes, one per tone. Each takes the person's name.
enum WishTone { warm, dua, friend, family, short, elder, child }

extension WishToneText on WishTone {
  String label(L l) => switch (this) {
    WishTone.warm => l.wishToneWarm,
    WishTone.dua => l.wishToneDua,
    WishTone.friend => l.wishToneFriend,
    WishTone.family => l.wishToneFamily,
    WishTone.short => l.wishToneShort,
    WishTone.elder => l.wishToneElder,
    WishTone.child => l.wishToneChild,
  };

  String message(L l, String name) => switch (this) {
    WishTone.warm => l.wishMsgWarm(name),
    WishTone.dua => l.wishMsgDua(name),
    WishTone.friend => l.wishMsgFriend(name),
    WishTone.family => l.wishMsgFamily(name),
    WishTone.short => l.wishMsgShort(name),
    WishTone.elder => l.wishMsgElder(name),
    WishTone.child => l.wishMsgChild(name),
  };
}
