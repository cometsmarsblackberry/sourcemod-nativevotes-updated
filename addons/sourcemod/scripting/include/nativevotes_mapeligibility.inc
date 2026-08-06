#if defined _nativevotes_mapeligibility_included
	#endinput
#endif
#define _nativevotes_mapeligibility_included

/**
 * Returns whether FindMap confirmed that a map is currently available.
 *
 * TF2 returns FindMap_PossiblyAvailable for Workshop maps that are known but
 * still refreshing, downloading, or in an error state. Those maps can be
 * downloaded during a blocking level change, but must not be offered in a vote
 * that promises an immediately usable result.
 */
stock bool NativeVotes_IsMapResultAvailable(FindMapResult result)
{
	return result == FindMap_Found
		|| result == FindMap_FuzzyMatch
		|| result == FindMap_NonCanonical;
}

/**
 * Resolves a map and returns whether it is currently available.
 */
stock bool NativeVotes_FindAvailableMap(
	const char[] mapName,
	char[] resolvedMap,
	int maxlen)
{
	return NativeVotes_IsMapResultAvailable(FindMap(mapName, resolvedMap, maxlen));
}
