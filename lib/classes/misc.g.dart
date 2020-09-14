// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'misc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map json) {
  return User()
    ..meta = json['meta'] == null
        ? null
        : UserMetadata.fromJson((json['meta'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          ))
    ..friendList = (json['friendList'] as Map)?.map(
      (k, e) => MapEntry(k as String, e as String),
    )
    ..friendsPendingResponse = (json['friendsPendingResponse'] as Map)?.map(
      (k, e) => MapEntry(k as String, e as String),
    )
    ..friendRequests = (json['friendRequests'] as Map)?.map(
      (k, e) => MapEntry(k as String, e as String),
    )
    ..schemesInEditor = (json['schemesInEditor'] as Map)?.map(
      (k, e) => MapEntry(k as String, e as String),
    )
    ..schemesOwned = (json['schemesOwned'] as Map)?.map(
      (k, e) => MapEntry(k as String, e as String),
    )
    ..challengeRequests = (json['challengeRequests'] as Map)?.map(
      (k, e) => MapEntry(k as String, e as String),
    )
    ..challengeInProgressId = json['challengeInProgressId'] as String;
}

Map<String, dynamic> _$UserToJson(User instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('meta', instance.meta?.toJson());
  writeNotNull('friendList', instance.friendList);
  writeNotNull('friendsPendingResponse', instance.friendsPendingResponse);
  writeNotNull('friendRequests', instance.friendRequests);
  writeNotNull('schemesInEditor', instance.schemesInEditor);
  writeNotNull('schemesOwned', instance.schemesOwned);
  writeNotNull('challengeRequests', instance.challengeRequests);
  writeNotNull('challengeInProgressId', instance.challengeInProgressId);
  return val;
}

UserMetadata _$UserMetadataFromJson(Map json) {
  return UserMetadata()
    ..userName = json['userName'] as String
    ..displayName = json['displayName'] as String
    ..email = json['email'] as String
    ..uid = json['uid'] as String
    ..joinDate = json['joinDate'] == null
        ? null
        : DateTime.parse(json['joinDate'] as String)
    ..imgId = json['imgId'] as String;
}

Map<String, dynamic> _$UserMetadataToJson(UserMetadata instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('userName', instance.userName);
  writeNotNull('displayName', instance.displayName);
  writeNotNull('email', instance.email);
  writeNotNull('uid', instance.uid);
  writeNotNull('joinDate', instance.joinDate?.toIso8601String());
  writeNotNull('imgId', instance.imgId);
  return val;
}

SchemeMetadata _$SchemeMetadataFromJson(Map json) {
  return SchemeMetadata()
    ..schemeID = json['schemeID'] as String
    ..gameName = json['gameName'] as String
    ..gameNickName = json['gameNickName'] as String
    ..rosterNum = json['rosterNum'] as int
    ..upvotes = json['upvotes'] as int
    ..releaseYear = json['releaseYear'] as int
    ..iconImgId = json['iconImgId'] as String
    ..maxFighters = json['maxFighters'] as int;
}

Map<String, dynamic> _$SchemeMetadataToJson(SchemeMetadata instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('schemeID', instance.schemeID);
  writeNotNull('gameName', instance.gameName);
  writeNotNull('gameNickName', instance.gameNickName);
  writeNotNull('rosterNum', instance.rosterNum);
  writeNotNull('upvotes', instance.upvotes);
  writeNotNull('releaseYear', instance.releaseYear);
  writeNotNull('iconImgId', instance.iconImgId);
  writeNotNull('maxFighters', instance.maxFighters);
  return val;
}

GameScheme _$GameSchemeFromJson(Map json) {
  return GameScheme(
    json['meta'] == null
        ? null
        : SchemeMetadata.fromJson((json['meta'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          )),
  )
    ..roster = (json['roster'] as List)
        ?.map((e) => e == null
            ? null
            : FighterScheme.fromJson((e as Map)?.map(
                (k, e) => MapEntry(k as String, e),
              )))
        ?.toList()
    ..grid = json['grid'] == null
        ? null
        : SelectGrid.fromJson((json['grid'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          ));
}

Map<String, dynamic> _$GameSchemeToJson(GameScheme instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('meta', instance.meta?.toJson());
  writeNotNull('roster', instance.roster?.map((e) => e?.toJson())?.toList());
  writeNotNull('grid', instance.grid?.toJson());
  return val;
}

SelectGrid _$SelectGridFromJson(Map json) {
  return SelectGrid()
    ..selectGrid = (json['selectGrid'] as List)
        ?.map((e) => (e as List)
            ?.map((e) => e == null
                ? null
                : Square.fromJson((e as Map)?.map(
                    (k, e) => MapEntry(k as String, e),
                  )))
            ?.toList())
        ?.toList()
    ..dim = json['dim'] == null
        ? null
        : Dimensions.fromJson((json['dim'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          ));
}

Map<String, dynamic> _$SelectGridToJson(SelectGrid instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(
      'selectGrid',
      instance.selectGrid
          ?.map((e) => e?.map((e) => e?.toJson())?.toList())
          ?.toList());
  writeNotNull('dim', instance.dim?.toJson());
  return val;
}

Dimensions _$DimensionsFromJson(Map json) {
  return Dimensions(
    json['maxRow'] as int,
    json['maxCol'] as int,
  );
}

Map<String, dynamic> _$DimensionsToJson(Dimensions instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('maxRow', instance.maxRow);
  writeNotNull('maxCol', instance.maxCol);
  return val;
}

Square _$SquareFromJson(Map json) {
  return Square(
    json['fighter'] == null
        ? null
        : FighterScheme.fromJson((json['fighter'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          )),
  );
}

Map<String, dynamic> _$SquareToJson(Square instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('fighter', instance.fighter?.toJson());
  return val;
}

FighterScheme _$FighterSchemeFromJson(Map json) {
  return FighterScheme(
    json['fighterName'] as String,
    json['iconImgId'] as String,
    (json['variants'] as List)?.map((e) => e as String)?.toList(),
  )
    ..gridX = json['gridX'] as int
    ..gridY = json['gridY'] as int
    ..associatedGameID = json['associatedGameID'] as String
    ..fighterID = json['fighterID'] as String;
}

Map<String, dynamic> _$FighterSchemeToJson(FighterScheme instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('gridX', instance.gridX);
  writeNotNull('gridY', instance.gridY);
  writeNotNull('associatedGameID', instance.associatedGameID);
  writeNotNull('fighterID', instance.fighterID);
  writeNotNull('fighterName', instance.fighterName);
  writeNotNull('iconImgId', instance.iconImgId);
  writeNotNull('variants', instance.variants);
  return val;
}

Challenge _$ChallengeFromJson(Map json) {
  return Challenge()
    ..meta = json['meta'] == null
        ? null
        : ChallengeMeta.fromJson((json['meta'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          ))
    ..state = json['state'] == null
        ? null
        : ChallengeStatus.fromJson((json['state'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          ))
    ..scheme = json['scheme'] == null
        ? null
        : GameScheme.fromJson((json['scheme'] as Map)?.map(
            (k, e) => MapEntry(k as String, e),
          ))
    ..status = json['status'] as String;
}

Map<String, dynamic> _$ChallengeToJson(Challenge instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('meta', instance.meta?.toJson());
  writeNotNull('state', instance.state?.toJson());
  writeNotNull('scheme', instance.scheme?.toJson());
  writeNotNull('status', instance.status);
  return val;
}

ChallengeStatus _$ChallengeStatusFromJson(Map json) {
  return ChallengeStatus()
    ..p1In = json['p1In'] as bool
    ..p2In = json['p2In'] as bool
    ..player1Fighters = (json['player1Fighters'] as Map)?.map(
      (k, e) => MapEntry(
          k as String,
          e == null
              ? null
              : FighterScheme.fromJson((e as Map)?.map(
                  (k, e) => MapEntry(k as String, e),
                ))),
    )
    ..player2Fighters = (json['player2Fighters'] as Map)?.map(
      (k, e) => MapEntry(
          k as String,
          e == null
              ? null
              : FighterScheme.fromJson((e as Map)?.map(
                  (k, e) => MapEntry(k as String, e),
                ))),
    );
}

Map<String, dynamic> _$ChallengeStatusToJson(ChallengeStatus instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('p1In', instance.p1In);
  writeNotNull('p2In', instance.p2In);
  writeNotNull('player1Fighters',
      instance.player1Fighters?.map((k, e) => MapEntry(k, e?.toJson())));
  writeNotNull('player2Fighters',
      instance.player2Fighters?.map((k, e) => MapEntry(k, e?.toJson())));
  return val;
}

ChallengeMeta _$ChallengeMetaFromJson(Map json) {
  return ChallengeMeta()
    ..challengeId = json['challengeId'] as String
    ..schemeId = json['schemeId'] as String
    ..schemeName = json['schemeName'] as String
    ..schemeImgId = json['schemeImgId'] as String
    ..maxFighters = json['maxFighters'] as int
    ..player1Username = json['player1Username'] as String
    ..player2Username = json['player2Username'] as String
    ..player1Present = json['player1Present'] as bool
    ..player2Present = json['player2Present'] as bool;
}

Map<String, dynamic> _$ChallengeMetaToJson(ChallengeMeta instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('challengeId', instance.challengeId);
  writeNotNull('schemeId', instance.schemeId);
  writeNotNull('schemeName', instance.schemeName);
  writeNotNull('schemeImgId', instance.schemeImgId);
  writeNotNull('maxFighters', instance.maxFighters);
  writeNotNull('player1Username', instance.player1Username);
  writeNotNull('player2Username', instance.player2Username);
  writeNotNull('player1Present', instance.player1Present);
  writeNotNull('player2Present', instance.player2Present);
  return val;
}
