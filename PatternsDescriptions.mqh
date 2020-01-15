//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2018, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#define PATTERNS_COUNT 6

enum PATTERN_INDEX {
   BULLISH_GARTLEY=0,
   BEARISH_GARTLEY,
   BULLISH_ABCD,
   BEARISH_ABCD,
   BULLISH_BUTTERFLY,
   BEARISH_BUTTERFLY,
};

PATTERN_INDEX FIVE_POINTERS_PATTERNS[4] = {
   BULLISH_GARTLEY,
   BEARISH_GARTLEY,
   BULLISH_BUTTERFLY,
   BEARISH_BUTTERFLY
};

PATTERN_INDEX FOUR_POINTERS_PATTERNS[2] = {
   BULLISH_ABCD,
   BEARISH_ABCD
};




struct PATTERN_DESCRIPTOR {
   PATTERN_INDEX     index;
   double            XAMin;
   double            XAMax;
   double            ABMin;
   double            ABMax;
   double            BCMin;
   double            BCMax;
   double            XADMin;
   double            XADMax;
};

struct PATTERN_INSTANCE {
   PATTERN_INDEX     index;
   PATTERN_DESCRIPTOR patternDescriptor;
   datetime          XDateTime;
   datetime          ADateTime;
   datetime          BDateTime;
   datetime          CDateTime;
   datetime          DDateTime;
   double            X;
   double            A;
   double            B;
   double            C;
   double            D;
};

PATTERN_DESCRIPTOR patternsDescriptors[PATTERNS_COUNT];

//+------------------------------------------------------------------+
//| Popula o array com as ratios de fibo de cada Padrão Harmônico    |
//+------------------------------------------------------------------+
void PopulatePatternsDescriptors() {
   PATTERN_DESCRIPTOR bullishGartley = { BULLISH_GARTLEY, 0.618, 0.618, 0.618, 0.786, 1.27, 1.618, 0.786, 0.786 };
   PATTERN_DESCRIPTOR bearishGartley = { BEARISH_GARTLEY, 0.618, 0.618, 0.618, 0.786, 1.27, 1.618, 0.786, 0.786 };
   PATTERN_DESCRIPTOR bullishABCD = { BULLISH_ABCD, 0, 0, 0.618, 0.786, 1.27, 1.618, 0, 0 };
   PATTERN_DESCRIPTOR bearishABCD = { BEARISH_ABCD, 0, 0, 0.618, 0.786, 1.27, 1.618, 0, 0 };
   PATTERN_DESCRIPTOR bullishButterfly = { BULLISH_BUTTERFLY, 0.786, 0.786, 0.618, 0.786, 1.618, 1.618, 1.27, 1.618 };
   PATTERN_DESCRIPTOR bearishButterfly = { BEARISH_BUTTERFLY, 0.786, 0.786, 0.618, 0.786, 1.618, 1.618, 1.27, 1.618 };
   
   AddPatternDescriptorToArray(bullishGartley);
   AddPatternDescriptorToArray(bearishGartley);
   AddPatternDescriptorToArray(bullishABCD);
   AddPatternDescriptorToArray(bearishABCD);
   AddPatternDescriptorToArray(bullishButterfly);
   AddPatternDescriptorToArray(bearishButterfly);
}

void AddPatternDescriptorToArray(PATTERN_DESCRIPTOR &patternDescriptor) {
   patternsDescriptors[patternDescriptor.index] = patternDescriptor;
}

//+------------------------------------------------------------------+
