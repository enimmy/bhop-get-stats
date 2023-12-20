
int BgsGetHUDTarget(int client, int fallback = -1) {
	int target = fallback;
	if(IsClientObserver(client)) {
		int iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
		if (iObserverMode >= 3 && iObserverMode <= 7) {
			int iTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			if (BgsIsValidClient(iTarget)) {
				target = iTarget;
			}
		}
	}
	return target;
}

bool BgsIsValidClient(int client, bool bAlive = false) {
	return (client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && (!bAlive || IsPlayerAlive(client)));
}

void BgsSetCookie(int client, Cookie hCookie, int n)
{
	char strCookie[64];
	IntToString(n, strCookie, sizeof(strCookie));
	SetClientCookie(client, hCookie, strCookie);
}

int GetIntSubValue(int num, int position, int binaryShift, int binaryMask) {
	return (num >> position * binaryShift) & binaryMask;
}

void SetIntSubValue(int &editNum, int insertVal, int position, int binaryShift, int binaryMask) {
	editNum = (editNum & ~(binaryMask << (position * binaryShift))) | ((insertVal & binaryMask) << (position * binaryShift));
}

float GetAdjustedHudCoordinate(int value, float scaler, float bias) {
	if(value < 0 || value > RoundToFloor(scaler)) {
		return -1.0;
	}
	float adjVal = (value / scaler) - bias;
	if(adjVal <= 0.0) {
		return -1.0;
	}
	return adjVal;
}

int HudCoordinateToInt(float value, int scaler, int min, int max) {
	if(value != -1.0 && (value < 0 || value > 1.0)) {
		return 0;
	}
	int adjVal = RoundToFloor(value * scaler);
	if(adjVal > max) {
		adjVal = max;
	}
	if(adjVal < min) {
		adjVal = min;
	}
	return adjVal;
}
