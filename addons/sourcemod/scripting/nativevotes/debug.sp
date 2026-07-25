bool IsDebugLoggingEnabled(int level)
{
	return g_ConVars[debug_level] != null && g_ConVars[debug_level].IntValue >= level;
}

void DebugLog(int level, const char[] format, any ...)
{
	if (!IsDebugLoggingEnabled(level))
	{
		return;
	}

	char message[512];
	VFormat(message, sizeof(message), format, 3);
	LogMessage("[debug:%d] %s", level, message);
}

void DebugLogMapList(int level, const char[] stage, StringMap mapList)
{
	if (!IsDebugLoggingEnabled(level))
	{
		return;
	}

	int workshopPaths;
	int fullWorkshopNames;
	char firstFullWorkshopName[PLATFORM_MAX_PATH];
	char map[PLATFORM_MAX_PATH];

	StringMapSnapshot snapshot = mapList.Snapshot();
	for (int i = 0; i < snapshot.Length; i++)
	{
		snapshot.GetKey(i, map, sizeof(map));

		bool hasWorkshopPath = StrContains(map, "workshop/", false) == 0;
		bool hasWorkshopSuffix = StrContains(map, ".ugc", false) != -1;

		if (hasWorkshopPath)
		{
			workshopPaths++;
		}

		if (hasWorkshopPath && hasWorkshopSuffix)
		{
			fullWorkshopNames++;
			if (firstFullWorkshopName[0] == '\0')
			{
				strcopy(firstFullWorkshopName, sizeof(firstFullWorkshopName), map);
			}
		}
	}
	delete snapshot;

	DebugLog(level, "%s: unique_maps=%d workshop_paths=%d full_workshop_names=%d",
		stage, mapList.Size, workshopPaths, fullWorkshopNames);

	if (firstFullWorkshopName[0] != '\0')
	{
		DebugLog(level, "%s: first_full_workshop_name=%s", stage, firstFullWorkshopName);
	}
}

void DebugLogMapStringTable(int level, const char[] stage)
{
	if (!IsDebugLoggingEnabled(level))
	{
		return;
	}

	char stringTable[64] = "ServerMapCycle";
	if (FindSendPropInfo("CTFGameRulesProxy", "m_bPlayingMannVsMachine") > 0 && GameRules_GetProp("m_bPlayingMannVsMachine"))
	{
		Format(stringTable, sizeof(stringTable), "%sMvM", stringTable);
	}

	int stringTableIndex = FindStringTable(stringTable);
	if (stringTableIndex == INVALID_STRING_TABLE)
	{
		DebugLog(level, "%s: string table %s was not found", stage, stringTable);
		return;
	}

	int stringIndex = FindStringIndex(stringTableIndex, stringTable);
	if (stringIndex == INVALID_STRING_INDEX)
	{
		DebugLog(level, "%s: entry %s was not found in string table index %d",
			stage, stringTable, stringTableIndex);
		return;
	}

	int length = GetStringTableDataLength(stringTableIndex, stringIndex);
	if (length <= 0)
	{
		DebugLog(level, "%s: string table data is empty (bytes=%d)", stage, length);
		return;
	}

	char[] mapData = new char[length];
	GetStringTableData(stringTableIndex, stringIndex, mapData, length);
	int trimmedLength = TrimString(mapData);

	StringMap mapList = new StringMap();
	int parsedMaps;
	if (mapData[0] != '\0')
	{
		parsedMaps = ExplodeStringToStringMap(mapData, "\n", mapList,
			PLATFORM_MAX_PATH, ImplodePart_Key);
	}

	DebugLog(level, "%s: table=%s table_index=%d entry_index=%d bytes=%d trimmed_bytes=%d parsed_maps=%d",
		stage, stringTable, stringTableIndex, stringIndex, length, trimmedLength, parsedMaps);
	DebugLogMapList(level, stage, mapList);

	delete mapList;
}

int DebugHashString(const char[] value)
{
	int hash = 5381;
	for (int i = 0; value[i] != '\0'; i++)
	{
		hash = ((hash << 5) + hash) ^ value[i];
	}

	return hash;
}

void DebugVerifyMapStringTableWrite(int stringTableIndex, int stringIndex,
	int expectedLength, int expectedTextLength, int expectedTextHash)
{
	if (!IsDebugLoggingEnabled(1))
	{
		return;
	}

	int storedLength = GetStringTableDataLength(stringTableIndex, stringIndex);
	if (storedLength <= 0)
	{
		DebugLog(1, "map list write verification: expected_bytes=%d stored_bytes=%d",
			expectedLength, storedLength);
		return;
	}

	char[] storedData = new char[storedLength];
	GetStringTableData(stringTableIndex, stringIndex, storedData, storedLength);

	int storedTextLength = strlen(storedData);
	int storedTextHash = DebugHashString(storedData);
	bool lengthMatch = expectedLength == storedLength;
	bool textMatch = expectedTextLength == storedTextLength
		&& expectedTextHash == storedTextHash;

	DebugLog(1, "map list write verification: expected_bytes=%d stored_bytes=%d expected_text_bytes=%d stored_text_bytes=%d expected_hash=%d stored_hash=%d length_match=%d text_match=%d",
		expectedLength, storedLength, expectedTextLength, storedTextLength,
		expectedTextHash, storedTextHash, lengthMatch, textMatch);
}

void DebugLogVoteSetup(int client, ArrayList voteTypes)
{
	if (!IsDebugLoggingEnabled(1))
	{
		return;
	}

	int enabled;
	bool kickEnabled;
	bool changeLevelEnabled;
	bool nextLevelEnabled;
	bool scrambleEnabled;

	for (int i = 0; i < voteTypes.Length; i++)
	{
		CallVoteListData voteType;
		voteTypes.GetArray(i, voteType, sizeof(CallVoteListData));

		if (voteType.CallVoteList_VoteEnabled)
		{
			enabled++;
			switch (voteType.CallVoteList_VoteType)
			{
				case NativeVotesOverride_Kick:
				{
					kickEnabled = true;
				}
				case NativeVotesOverride_ChgLevel:
				{
					changeLevelEnabled = true;
				}
				case NativeVotesOverride_NextLevel:
				{
					nextLevelEnabled = true;
				}
				case NativeVotesOverride_Scramble:
				{
					scrambleEnabled = true;
				}
			}
		}

		DebugLog(2, "callvote setup item: client=%N index=%d type=%d enabled=%d",
			client, i, voteType.CallVoteList_VoteType, voteType.CallVoteList_VoteEnabled);
	}

	DebugLog(1, "callvote setup response: client=%N userid=%d total=%d enabled=%d kick=%d changelevel=%d nextlevel=%d scramble=%d",
		client, GetClientUserId(client), voteTypes.Length, enabled, kickEnabled,
		changeLevelEnabled, nextLevelEnabled, scrambleEnabled);
}
