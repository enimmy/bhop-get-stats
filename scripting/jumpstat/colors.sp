#define COLORS_NUMBER 9

enum //enum for colors same indexes as colors below
{
	Red, //for all colors structs, first 5 idxs are default, dont reorder them
	Orange,
	Green,
	Cyan,
	White,
	Yellow,
	Blue,
	Purple,
	Pink
};

char g_sBstatColorStrs[][] = { //strings for colors at same indexes as colors below
	"Red",
	"Orange",
	"Green",
	"Cyan",
	"White",
	"Yellow",
	"Blue",
	"Purple",
	"Pink"
};

char g_sBstatColorsHex[][] = {
	"\x07ff0000",
	"\x07ffa500",
	"\x0700ff00",
	"\x0700ffff",
	"\x07ffffff",
	"\x07ffff00",
	"\x070000ff",
	"\x07800080",
	"\x07ee00ff"
};

int g_iBstatColors[][] = { //general colors
	{255, 0, 0},
	{255, 165, 0},
	{0, 255, 0},
	{0, 255, 255},
	{255, 255, 255},
	{255, 255, 0},
	{0, 0, 255},
	{128, 0, 128},
	{238, 0, 255}
};

int g_iJhudSpeedValues[][] = { //jhud colors based on speeds for first 6 or first 16
	{},  				    // null
	{280, 282, 287, 289},  	// 1
	{366, 370, 375, 380},  	// 2
	{438, 442, 450, 455},  	// 3
	{500, 505, 515, 525},  	// 4
	{555, 560, 570, 580},  	// 5
	{605, 610, 620, 633},  	// 6
	{655, 665, 675, 680},  	// 7
	{700, 710, 725, 730}, 	// 8
	{740, 750, 765, 770},  	// 9
	{780, 790, 805, 810},  	// 10
	{810, 820, 840, 850},  	// 11
	{850, 860, 875, 885},  	// 12
	{880, 900, 900, 920},  	// 13
	{910, 920, 935, 955},  	// 14
	{945, 955, 965, 990},  	// 15
	{970, 980, 1000, 1020} 	// 16
};

int GetGainColorIdx(float gain) {
	if(gain > 100)
	{
		return GainReallyBad;
	}
	else if(gain >= 90)
	{
		return GainReallyGood;
	}
	else if (gain >= 80)
	{
		return GainGood;
	}
	else if(gain >= 70)
	{
		return GainMeh;
	}
	else if(gain >= 60)
	{
		return GainBad;
	}
	else
	{
		return GainReallyBad;
	}
}

int GetSpeedColorIdx(int jump, int speed) {
	if(jump < 0 || jump > 16)
	{
		return -1;
	}

	if(speed >= g_iJhudSpeedValues[jump][3])
	{
		return GainReallyGood;
	}
	else if(speed > g_iJhudSpeedValues[jump][2])
	{
		return GainGood;
	}
	else if(speed > g_iJhudSpeedValues[jump][1])
	{
		return GainMeh;
	}
	else if(speed > g_iJhudSpeedValues[jump][0])
	{
		return GainBad;
	}
	else
	{
		return GainReallyBad;
	}
}
