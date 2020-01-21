//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2018, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include "PatternsDescriptions.mqh"
#define FLOATING_POINTS 4

//-------------------------------------------------
// Método para calcular/detectar Gartley Bullish  |
//-------------------------------------------------
bool CalculateBullishGartley(PATTERN_INSTANCE &pattern) {
   double X,A,B,C,D;

   X = NormalizeDoubleDefault( pattern.X );
   A = NormalizeDoubleDefault( pattern.A );
   B = NormalizeDoubleDefault( pattern.B );
   C = NormalizeDoubleDefault( pattern.C );
   D = NormalizeDoubleDefault( pattern.D );

   double AB1 = (A - X) * 0.618;
   double AB2 = (A - X) * 0.5;

   if(B >= (A - AB1) && B <= (A - AB2)) {

      double BC1 = (A - B) * 0.618;
      double BC2 = (A - B) * 0.886;

      if(C >= (B + BC1) && C <= (B + BC2)) {

         double XA1 = (A - X) * 0.986;
         double XA2 = (A - X) * 0.786;
         if(D >= (A - XA1) && D <= (A - XA2)) {
            return true;
         }
      }

   }

   return false;

}


//+-------------------------------------------------+
//| Método para calcular/detectar Gartley Bullish   |
//+-------------------------------------------------+
bool CalculateBearishGartley(PATTERN_INSTANCE &pattern) {
   double X, A, B, C, D, XAMin, XAMax, ABMin, ABMax, BCMin, BCMax;

   X = NormalizeDoubleDefault( pattern.X );
   A = NormalizeDoubleDefault( pattern.A );
   B = NormalizeDoubleDefault( pattern.B );
   C = NormalizeDoubleDefault( pattern.C );
   D = NormalizeDoubleDefault( pattern.D );

   XAMin = X - ((X - A) * .7);
   XAMax = X - ((X - A) * .618);

   if(B >= XAMin && B <= XAMax) {


      ABMin = B - ((B - A) * 0.786);
      ABMax = B - ((B - A) * 0.618);

      if(C >= ABMin && C <= ABMax) {

         BCMin = B + ((B - C) * 1.27);
         BCMax =  B + ((B - C) * 1.618);

         if(D >= BCMin && D <= BCMax) {

            return true;

         }

      }

   }

   return false;
}

//+--------------------------------+
//| Calcula o Padrão Bullish ABCD  |
//+--------------------------------+
bool CalculateBullishABCD( PATTERN_INSTANCE &pattern ) {
   double A, B, C, D, ABMin, ABMax, CDMin, CDMax;

   A = NormalizeDoubleDefault( pattern.A );
   B = NormalizeDoubleDefault( pattern.B );
   C = NormalizeDoubleDefault( pattern.C );
   D = NormalizeDoubleDefault( pattern.D );

   /*
      Carney (1999, p. 118):
      I consider the completion of a exact AB = CD
      a minimun requirement before entering a trade.
   */
   if((A - B) == (C - D)) {

      ABMin = B + ((A - B) * .618);
      ABMax = B + ((A - B) * .786);

      if(C >= ABMin && C <= ABMax) {

         CDMin = C - ((C - B) * 1.618);
         CDMax = C - ((C - B) * 1.27);

         if(D >= CDMin && D <= CDMax) {
            //Print("A: ",A," B: ", B, " C: ", C, " D: ", D);
            return true;
         }
      }
   }
   return false;
}

//+-----------------------------------------+
//| Calcula o Padrão Harmônico Bearish ABCD |
//+-----------------------------------------+
bool CalculateBearishABCD(PATTERN_INSTANCE &pattern) {
   double A, B, C, D, ABMin, ABMax, CDMin, CDMax;

   A = NormalizeDoubleDefault( pattern.A );
   B = NormalizeDoubleDefault( pattern.B );
   C = NormalizeDoubleDefault( pattern.C );
   D = NormalizeDoubleDefault( pattern.A );

   if((B - A)  == (D - C)) {

      ABMin = A + ((B - A) * .618);
      ABMax = A + ((B - A) * .786);

      if(C >= ABMin && C <= ABMax) {

         CDMin = C + ((B - A) * 1.272);
         CDMax = C + ((B - A) * 1.618);

         if(C >= CDMin && C <= CDMax) {
            return true;
         }
      }
   }
   return false;
}

//+-------------------------------------------------------------+
//| Método genérico para detectar os Padrões Harmônicos Bullish |
//| com cinco pontos gráficos.                                  |
//+-------------------------------------------------------------+
bool CalculateBullishFivePointersPattern( PATTERN_INSTANCE &pattern ) {
   double X, A, B, C, D;

   X = NormalizeDoubleDefault( pattern.X );
   A = NormalizeDoubleDefault( pattern.A );
   B = NormalizeDoubleDefault( pattern.B );
   C = NormalizeDoubleDefault( pattern.C );
   D = NormalizeDoubleDefault( pattern.D );

   return (
             VerifyFibonnaciRatio( A, X, B, pattern.patternDescriptor.XAMax, pattern.patternDescriptor.XAMin ) &&
             VerifyFibonnaciRatio( A, B, C, pattern.patternDescriptor.ABMax, pattern.patternDescriptor.ABMin ) &&
             VerifyFibonnaciRatio( C, B, D, pattern.patternDescriptor.BCMax, pattern.patternDescriptor.BCMin ) &&
             VerifyFibonnaciRatio( A, X, D, pattern.patternDescriptor.XADMax, pattern.patternDescriptor.XADMin )
          );
}

//+-------------------------------------------------------------+
//| Método genérico para detectar os Padrões Harmônicos Bearish |
//| com cinco pontos gráficos.                                  |
//+-------------------------------------------------------------+
bool CalculateBearishFivePointersPattern( PATTERN_INSTANCE &pattern ) {
   double X, A, B, C, D;

   X = NormalizeDoubleDefault( pattern.X );
   A = NormalizeDoubleDefault( pattern.A );
   B = NormalizeDoubleDefault( pattern.B );
   C = NormalizeDoubleDefault( pattern.C );
   D = NormalizeDoubleDefault( pattern.D );

   return (
             VerifyFibonnaciRatio( X, A, B, pattern.patternDescriptor.XAMax, pattern.patternDescriptor.XAMin ) &&
             VerifyFibonnaciRatio( B, A, C, pattern.patternDescriptor.ABMax, pattern.patternDescriptor.ABMin ) &&
             VerifyFibonnaciRatio( B, C, D, pattern.patternDescriptor.BCMax, pattern.patternDescriptor.BCMin ) &&
             VerifyFibonnaciRatio( X, A, D, pattern.patternDescriptor.XADMax, pattern.patternDescriptor.XADMin )
          );

}

//+---------------------------------------------------------------------+
//| Verifica se o valor passado está dentro das ratios de fibo passadas |
//+---------------------------------------------------------------------+
bool VerifyFibonnaciRatio(double high, double low, double value, double highRatio, double lowRatio) {
   double ratio = ( high - value ) / ( high - low );
   return ( ratio >= lowRatio ) && ( ratio <= highRatio );
}

//+--------------------------------------------------------------------+
//| Método que normaliza valores double com um número de casas default |
//+--------------------------------------------------------------------+
double NormalizeDoubleDefault( double i ) {
   return NormalizeDouble( i, FLOATING_POINTS );
}
//+------------------------------------------------------------------+
