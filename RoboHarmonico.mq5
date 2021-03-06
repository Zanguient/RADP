//+------------------------------------------------------------------+
//|                                                RoboHarmonico.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

//--- Includes
#include <Trade\AccountInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <ChartObjects\ChartObjectsArrows.mqh>
#include <ChartObjects\ChartObjectsShapes.mqh>
#include <ChartObjects\ChartObjectsLines.mqh>
#include "HarmonicPatterns.mqh"

//--- Resources
#resource "\\Indicators\\fastZZ.ex5";


CAccountInfo infoConta;
CTrade trade;
CSymbolInfo ativoInfo;
COrderInfo ordensPendentes;
CChartObjectArrow topo, icone;
CChartObjectTrend linhaTrend;
CChartObjectTriangle triangulo;
HarmonicPatterns harmonicPatterns;

int idRobo = 1618033;

input int zzDeviation = 25;
int input zzCopyBufferSize = 1000;

// FastZZ handler
int zzHandle;

// Fastzz buffers
double zzTopPricesBuffer[];
double zzBottomPricesBuffer[];

// Date time buffer
datetime candleDatetimesBuffer[];

// Temporarily Arrays
double zzTopPrices[3];
double zzBottomPrices[3];
datetime zzTopDatetimes[3];
datetime zzBottomDatetimes[3];


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {

   zzHandle = iCustom(_Symbol, _Period, "::Indicators\\fastZZ.ex5", zzDeviation);

   if(zzHandle == INVALID_HANDLE) {
      Print("Falha ao criar o indicador ZigZag: ", GetLastError());
      return(INIT_FAILED);
   }

// define para acessar como timeseries
   ArraySetAsSeries(zzTopPricesBuffer, true);
   ArraySetAsSeries(zzBottomPricesBuffer, true);
   ArraySetAsSeries(candleDatetimesBuffer, true);

// ativo
   ativoInfo.Name(_Symbol);

   return(INIT_SUCCEEDED);

}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
// copia os datetimes
   if(CopyTime(_Symbol, _Period, 0, zzCopyBufferSize, candleDatetimesBuffer) < 0) {
      Print("Erro ao copiar tempos: ", GetLastError());
      return;
   }

// copia os topos
   if(CopyBuffer(zzHandle, 0, 0, zzCopyBufferSize, zzTopPricesBuffer) < 0) {
      Print("Erro ao copiar dados dos topos: ", GetLastError());
      return;
   }

// copia os fundos
   if(CopyBuffer(zzHandle, 1, 0, zzCopyBufferSize, zzBottomPricesBuffer) < 0) {
      Print("Erro ao copiar dados dos fundos: ", GetLastError());
      return;
   }

// Copia os topos e fundos para os arrays temporários
   GetZZBottoms();
   GetZZTops();


// Cria linhas de tendência do indicator FastZZ
   CreateZZTendencyLines();


// Padrões Harmônicos
   IsBearishABCD(); // Verifica se o Padrão Bearish ABCD foi formado e cria a sua figura
   IsBullishABCD(); // Verifica se o Padrão Bullish ABCD foi formado e cria a sua figura

   IsBullishGartley(); // Verifica se o Padrão Bullish Gartley foi formado e cria a sua figura
   IsBearishGartley(); // Verifica se o Padrão Bearish Gartley foi formado e cria a sua figura

   IsBullishButterfly();
   IsBearishButterfly();

   IsBullishBat();
   IsBearishBat();

   IsBullishCrab();
   IsBearishCrab();

   IsBullishDeepCrab();
   IsBearishDeepCrab();

   IsBullishShark();
   IsBearishShark();

}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrderHandler(double takeProfit, double stop, string label, bool isBullish = true) {
   double vol = ativoInfo.LotsMin();

   ativoInfo.Refresh(); // atualiza os dados do ativo
   return;
   
   bool isOrdemCompraAberta;
   if( isBullish  ) {
      isOrdemCompraAberta = buscarPosicaoAbertasByTipo( POSITION_TYPE_BUY );
   } else {
      isOrdemCompraAberta = buscarPosicaoAbertasByTipo( POSITION_TYPE_SELL );
   }

   if (!isOrdemCompraAberta) {
      if ( isBullish ) {
         abrirOrdem(ORDER_TYPE_BUY, ativoInfo.Ask(), vol, stop, takeProfit, label);
      } else {
         abrirOrdem(ORDER_TYPE_SELL, ativoInfo.Ask(), vol, stop, takeProfit, label);
      }
   }
}

//+---------------------------------------+
//| Verifica se é um Bullish Gartley      |
//+---------------------------------------+
void IsBullishGartley() {
   PATTERN_INSTANCE pattern = GetBullish5PointersPatternInstance( BULLISH_GARTLEY );
   if( harmonicPatterns.CalculateHarmonicPattern( pattern ) ) {
      CreatePatternsGraphic( pattern );
      Print(
         "BULLISH_GARTLEY;",
         true,";",
         pattern.X,";",
         pattern.A,";",
         pattern.B,";",
         pattern.C,";",
         pattern.D
      );
      OrderHandler( pattern.C, pattern.D, "BULLISH_GARTLEY");
   }
}

//+-----------------------------------+
//| Verifica se é um Bearish Gartley  |
//+-----------------------------------+
void IsBearishGartley() {
   PATTERN_INSTANCE pattern = GetPatternInstance( BEARISH_GARTLEY, false );

   if( harmonicPatterns.CalculateHarmonicPattern( pattern ) ) {
      CreatePatternsGraphic(pattern);
      Print(
         "BEARISH_GARTLEY;",
         false,";",
         pattern.X,";",
         pattern.A,";",
         pattern.B,";",
         pattern.C,";",
         pattern.D
      );
      OrderHandler( pattern.C, pattern.D, "BEARISH_GARTLEY", false);
   }
}

//+------------------------------------+
//| Verifica se é um Bullish Butterfly |
//+------------------------------------+
void IsBullishButterfly() {
   PATTERN_INSTANCE pattern = GetPatternInstance( BULLISH_BUTTERFLY, true );

   if( harmonicPatterns.CalculateHarmonicPattern( pattern ) ) {
      CreatePatternsGraphic( pattern );
      Print(
         "BULLISH_BUTTERFLY;",
         true,";",
         pattern.X,";",
         pattern.A,";",
         pattern.B,";",
         pattern.C,";",
         pattern.D
      );
      OrderHandler( pattern.C, pattern.D, "BULLISH_BUTTERFLY", true);
   }
}

//+------------------------------------+
//| Verifica se é um Bearish Butterfly |
//+------------------------------------+
void IsBearishButterfly() {
   PATTERN_INSTANCE pattern = GetPatternInstance( BEARISH_BUTTERFLY, false );

   if( harmonicPatterns.CalculateHarmonicPattern( pattern ) ) {
      CreatePatternsGraphic(pattern);
      Print(
         "BEARISH_BUTTERFLY;",
         false,";",
         pattern.X,";",
         pattern.A,";",
         pattern.B,";",
         pattern.C,";",
         pattern.D
      );
      OrderHandler( pattern.C, pattern.D, "BEARISH_BUTTERFLY", false);
   }
}

//+------------------------------+
//| Verifica se é um Bullish Bat |
//+------------------------------+
void IsBullishBat() {
   PATTERN_INSTANCE pattern = GetPatternInstance( BULLISH_BAT, true );

   if( harmonicPatterns.CalculateHarmonicPattern( pattern ) ) {
      CreatePatternsGraphic( pattern );
      Print(
         "BULLISH_BAT;",
         true,";",
         pattern.X,";",
         pattern.A,";",
         pattern.B,";",
         pattern.C,";",
         pattern.D
      );
      OrderHandler( pattern.C, pattern.D, "BULLISH_BAT", true);
   }
}

//+------------------------------+
//| Verifica se é um Bearish Bat |
//+------------------------------+
void IsBearishBat() {
   PATTERN_INSTANCE pattern = GetPatternInstance( BEARISH_BAT, false );

   if( harmonicPatterns.CalculateHarmonicPattern( pattern ) ) {
      CreatePatternsGraphic( pattern );
      Print(
         "BEARISH_BAT;",
         false,";",
         pattern.X,";",
         pattern.A,";",
         pattern.B,";",
         pattern.C,";",
         pattern.D
      );
       OrderHandler( pattern.C, pattern.D, "BULLISH_BAT", false);
   }
}

//+-------------------------------+
//| Verifica se é um Bullish Crab |
//+-------------------------------+
void IsBullishCrab() {
   PATTERN_INSTANCE pattern = GetPatternInstance( BULLISH_CRAB, true );

   if( harmonicPatterns.CalculateHarmonicPattern( pattern ) ) {
      CreatePatternsGraphic( pattern );
      Print(
         "BULLISH_CRAB;",
         true,";",
         pattern.X,";",
         pattern.A,";",
         pattern.B,";",
         pattern.C,";",
         pattern.D
      );
        OrderHandler( pattern.C, pattern.D, "BULLISH_CRAB", true);
   }
}

//+-------------------------------+
//| Verifica se é um Bearish Crab |
//+-------------------------------+
void IsBearishCrab() {
   PATTERN_INSTANCE pattern = GetPatternInstance( BEARISH_CRAB, false );

   if( harmonicPatterns.CalculateHarmonicPattern( pattern ) ) {
      CreatePatternsGraphic( pattern );
      Print(
         "BEARISH_CRAB;",
         false,";",
         pattern.X,";",
         pattern.A,";",
         pattern.B,";",
         pattern.C,";",
         pattern.D
      );
      OrderHandler( pattern.C, pattern.D, "BEARISH_CRAB", false);
   }
}

//+------------------------------------+
//| Verifica se é um Bullish Deep Crab |
//+------------------------------------+
void IsBullishDeepCrab() {
   PATTERN_INSTANCE pattern = GetPatternInstance( BULLISH_DEEP_CRAB, true );

   if( harmonicPatterns.CalculateHarmonicPattern( pattern ) ) {
      CreatePatternsGraphic( pattern );
      Print(
         "BULLISH_DEEP_CRAB;",
         true,";",
         pattern.X,";",
         pattern.A,";",
         pattern.B,";",
         pattern.C,";",
         pattern.D
      );
      OrderHandler( pattern.C, pattern.D, "BULLISH_DEEP_CRAB", true);
   }
}

//+------------------------------------+
//| Verifica se é um Bearish Deep Crab |
//+------------------------------------+
void IsBearishDeepCrab() {
   PATTERN_INSTANCE pattern = GetPatternInstance( BEARISH_DEEP_CRAB, false );

   if( harmonicPatterns.CalculateHarmonicPattern( pattern ) ) {
      CreatePatternsGraphic( pattern );
      Print(
         "BEARISH_DEEP_CRAB;",
         false,";",
         pattern.X,";",
         pattern.A,";",
         pattern.B,";",
         pattern.C,";",
         pattern.D
      );
      OrderHandler( pattern.C, pattern.D, "BEARISH_DEEP_CRAB", false);
   }
}


//+--------------------------------+
//| Verifica se é um Bullish Shark |
//+--------------------------------+
void IsBullishShark() {
   PATTERN_INSTANCE pattern = GetPatternInstance( BULLISH_SHARK, true );

   if( harmonicPatterns.CalculateHarmonicPattern( pattern ) ) {
      CreatePatternsGraphic( pattern );
      Print(
         "BULLISH_SHARK;",
         true,";",
         pattern.X,";",
         pattern.A,";",
         pattern.B,";",
         pattern.C,";",
         pattern.D
      );
       OrderHandler( pattern.C, pattern.D, "BULLISH_SHARK", true);
   }
}

//+--------------------------------+
//| Verifica se é um Bearish Shark |
//+--------------------------------+
void IsBearishShark() {
   PATTERN_INSTANCE pattern = GetPatternInstance( BEARISH_SHARK, false );

   if( harmonicPatterns.CalculateHarmonicPattern( pattern ) ) {
      CreatePatternsGraphic( pattern );
      Print(
         "BEARISH_SHARK;",
         false,";",
         pattern.X,";",
         pattern.A,";",
         pattern.B,";",
         pattern.C,";",
         pattern.D
      );
      OrderHandler( pattern.C, pattern.D, "BEARISH_SHARK", false);
   }
}


//+-----------------------------+
//| Verifica se é Bullish ABCD  |
//+-----------------------------+
void IsBullishABCD() {
   PATTERN_INSTANCE pattern = GetPatternInstance( BULLISH_ABCD, true );
   if( harmonicPatterns.CalculateHarmonicPattern( pattern ) ) {
      CreatePatternsGraphic( pattern, false );
      Print(
         "BULLISH_ABCD;",
         true,";",
         pattern.X,";",
         pattern.A,";",
         pattern.B,";",
         pattern.C,";",
         pattern.D
      );
      OrderHandler( pattern.C, pattern.D, "BULLISH_ABCD", true);
   }
}
//+-------------------------------+
//| Verifica se é um Bearish ABCD |
//+-------------------------------+
void IsBearishABCD() {
   PATTERN_INSTANCE pattern = GetPatternInstance( BEARISH_ABCD, false );
   if( harmonicPatterns.CalculateHarmonicPattern( pattern ) ) {
      CreatePatternsGraphic( pattern, false );
      Print(
         "BEARISH_ABCD;",
         false,";",
         pattern.X,";",
         pattern.A,";",
         pattern.B,";",
         pattern.C,";",
         pattern.D
      );
      OrderHandler( pattern.C, pattern.D, "BEARISH_ABCD", false);
   }
}

//+------------------------------------------------------------------+
//| Cria as linhas de tendências dos topos e fundos do Fast ZZ       |
//+------------------------------------------------------------------+
void CreateZZTendencyLines() {
   datetime dt_top1, dt_top2, dt_bottom1, dt_bottom2;
   double pc_top1, pc_top2, pc_bottom1, pc_bottom_2;

   dt_top1 = zzTopDatetimes[0];
   dt_top2 = zzTopDatetimes[2];
   dt_bottom1 = zzBottomDatetimes[0];
   dt_bottom2 = zzBottomDatetimes[2];

   pc_top1 = zzTopPrices[0];
   pc_top2 = zzTopPrices[2];
   pc_bottom1 = zzBottomPrices[0];
   pc_bottom_2 = zzBottomPrices[2];

   removerIcone("ZZ-TOP-TENDENCY-LINE");
   criarLinhaTendencia("ZZ-TOP-TENDENCY-LINE", dt_top2, pc_top2, dt_top1, pc_top1, clrPurple, STYLE_DASH, 1, true, false);

   removerIcone("ZZ-BOTTOM-TENDENCY-LINE");
   criarLinhaTendencia("ZZ-BOTTOM-TENDENCY-LINE", dt_bottom2, pc_bottom_2, dt_bottom1, pc_bottom1, clrOrange, STYLE_DASH, 1, true, false);
}

//+----------------------------------------+
//| Cria o gráfico dos padrões harmônicos  |
//+----------------------------------------+
void CreatePatternsGraphic(PATTERN_INSTANCE &pattern, bool isFivePointers = true) {
// Cria dois triangulos que representam o padrão

   if(isFivePointers) {
      criarTriangulo(
         "T-XAC "+ TimeToString(pattern.XDateTime),
         pattern.XDateTime, pattern.X,
         pattern.ADateTime, pattern.A,
         pattern.BDateTime, pattern.B,
         clrLightGreen, STYLE_SOLID, 1, false, false
      );

      criarTriangulo(
         "T-BCD "+ TimeToString(pattern.CDateTime),
         pattern.BDateTime, pattern.B,
         pattern.CDateTime, pattern.C,
         pattern.DDateTime, pattern.D,
         clrAquamarine, STYLE_SOLID, 1, false, false
      );
   } else {
      criarTriangulo(
         "T-ABC "+ TimeToString(pattern.ADateTime),
         pattern.ADateTime, pattern.A,
         pattern.BDateTime, pattern.B,
         pattern.CDateTime, pattern.C,
         clrLightGreen, STYLE_SOLID, 1, false, false
      );

      criarTriangulo(
         "T-BCD "+ TimeToString(pattern.BDateTime),
         pattern.BDateTime, pattern.B,
         pattern.CDateTime, pattern.C,
         pattern.DDateTime, pattern.D,
         clrAquamarine, STYLE_SOLID, 1, false, false
      );
   }
}


//+------------------------------------------------------------------+
//| Método que coloca os três últimos topos no array temporário      |
//+------------------------------------------------------------------+
void GetZZTops() {
   int size = ArraySize(zzTopPricesBuffer);
   int index = 0;
   for(int i = 0; i < size; i++) {

      if(zzTopPricesBuffer[i] != 0) {
         if(index == 0) {

            zzTopPrices[index] = harmonicPatterns.NormalizeDoubleDefault( zzTopPricesBuffer[i] );
            zzTopDatetimes[index] = candleDatetimesBuffer[i];

         } else if(index == 1) {

            zzTopPrices[index] = harmonicPatterns.NormalizeDoubleDefault( zzTopPricesBuffer[i] );
            zzTopDatetimes[index] = candleDatetimesBuffer[i];

         } else if(index == 2) {

            zzTopPrices[index] = harmonicPatterns.NormalizeDoubleDefault( zzTopPricesBuffer[i] );
            zzTopDatetimes[index] = candleDatetimesBuffer[i];
            break;

         }
         index++;
      }

   }
}

//+------------------------------------------------------------------+
//| Método que coloca os três últimos fundos no array temporário     |
//+------------------------------------------------------------------+
void GetZZBottoms() {
   int size = ArraySize(zzBottomPricesBuffer);
   int index = 0;
   for(int i = 0; i < size; i++) {

      if(zzBottomPricesBuffer[i] != 0) {
         if(index == 0) {

            zzBottomPrices[index] = harmonicPatterns.NormalizeDoubleDefault( zzBottomPricesBuffer[i] );
            zzBottomDatetimes[index] = candleDatetimesBuffer[i];

         } else if(index == 1) {

            zzBottomPrices[index] = harmonicPatterns.NormalizeDoubleDefault( zzBottomPricesBuffer[i] );
            zzBottomDatetimes[index] = candleDatetimesBuffer[i];


         } else if(index == 2) {

            zzBottomPrices[index] = harmonicPatterns.NormalizeDoubleDefault( zzBottomPricesBuffer[i] );
            zzBottomDatetimes[index] = candleDatetimesBuffer[i];
            break;
         }
         index++;
      }

   } // fim for fundo para obter apenas os três últimos fundos mais atuais
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PATTERN_INSTANCE GetPatternInstance( PATTERN_INDEX patternIndex, bool isBullish = true ) {
   if( VerifyPatternGroup( FIVE_POINTERS_PATTERNS, patternIndex ) ) {
      return Get5PointersPatternInstance( patternIndex, isBullish );
   }
   return Get4PointersPatternInstance( patternIndex, isBullish );
}

//+-----------------------------------------------------------------------------+
//| Verifica se o PATTERN_INDEX recebido faz parte do array de patterns recebido|
//+-----------------------------------------------------------------------------+
bool VerifyPatternGroup( PATTERN_INDEX &patternsIndexes[], PATTERN_INDEX patternIndex ) {
   int index = ArrayBsearch( patternsIndexes, patternIndex );
   PATTERN_INDEX result = patternsIndexes[index];
   return result == patternIndex;
}

//+----------------------------------------------------------+
//| Chama o método que cria a instância do PATTERN_INSTANCE  |
//| dos Padrões com 5 pontos verificando se é bullish ou não |
//+----------------------------------------------------------+
PATTERN_INSTANCE Get5PointersPatternInstance( PATTERN_INDEX patternIndex, bool isBullish ) {
   if( isBullish ) {
      return GetBullish5PointersPatternInstance( patternIndex );
   }
   return GetBearish5PointersPatternInstance( patternIndex );
}

//+----------------------------------------------------------+
//| Chama o método que cria a instância do PATTERN_INSTANCE  |
//| dos Padrões com 4 pontos verificando se é bullish ou não |
//+----------------------------------------------------------+
PATTERN_INSTANCE Get4PointersPatternInstance( PATTERN_INDEX patternIndex, bool isBullish ) {
   if(isBullish) {
      return GetBullish4PointersPatternInstance( patternIndex );
   }
   return GetBearish4PointersPatternInstance( patternIndex );
}



//+-----------------------------------------------+
//| Monta o objeto Pattern Instance para calcular |
//| os Padrões Harmônicos Bullish com 5 pontos    |
//+-----------------------------------------------+
PATTERN_INSTANCE GetBullish5PointersPatternInstance( PATTERN_INDEX patternIndex ) {
   PATTERN_INSTANCE patternInstance;
   patternInstance.index = patternIndex;
   patternInstance.isBullish = true;
   patternInstance.isFourPoints = false;
   patternInstance.patternDescriptor = harmonicPatterns.patternsDescriptors[patternIndex];

   patternInstance.X = zzBottomPrices[2];
   patternInstance.A = zzTopPrices[1];
   patternInstance.B = zzBottomPrices[1];
   patternInstance.C = zzTopPrices[0];
   patternInstance.D = zzBottomPrices[0];

   patternInstance.XDateTime = zzBottomDatetimes[2];
   patternInstance.ADateTime = zzTopDatetimes[1];
   patternInstance.BDateTime = zzBottomDatetimes[1];
   patternInstance.CDateTime = zzTopDatetimes[0];
   patternInstance.DDateTime = zzBottomDatetimes[0];

   return patternInstance;
}

//+-----------------------------------------------+
//| Monta o objeto Pattern Instance para calcular |
//| os Padrões Harmônicos Bearish com 5 pontos    |
//+-----------------------------------------------+
PATTERN_INSTANCE GetBearish5PointersPatternInstance( PATTERN_INDEX patternIndex ) {
   PATTERN_INSTANCE patternInstance;
   patternInstance.index = patternIndex;
   patternInstance.isBullish = false;
   patternInstance.isFourPoints = false;
   patternInstance.patternDescriptor = harmonicPatterns.patternsDescriptors[patternIndex];

   patternInstance.X = zzTopPrices[2];
   patternInstance.A = zzBottomPrices[1];
   patternInstance.B = zzTopPrices[1];
   patternInstance.C = zzBottomPrices[0];
   patternInstance.D = zzTopPrices[0];

   patternInstance.XDateTime = zzTopDatetimes[2];
   patternInstance.ADateTime = zzBottomDatetimes[1];
   patternInstance.BDateTime = zzTopDatetimes[1];
   patternInstance.CDateTime = zzBottomDatetimes[0];
   patternInstance.DDateTime = zzTopDatetimes[0];

   return patternInstance;
}

//+-----------------------------------------------+
//| Monta o objeto Pattern Instance para calcular |
//| os Padrões Harmônicos Bullish com 4 pontos    |
//+-----------------------------------------------+
PATTERN_INSTANCE GetBullish4PointersPatternInstance( PATTERN_INDEX patternIndex ) {
   PATTERN_INSTANCE patternInstance;
   patternInstance.index = patternIndex;
   patternInstance.isBullish = true;
   patternInstance.isFourPoints = true;
   patternInstance.patternDescriptor = harmonicPatterns.patternsDescriptors[patternIndex];

   patternInstance.A = zzTopPrices[1];
   patternInstance.B = zzBottomPrices[1];
   patternInstance.C = zzTopPrices[0];
   patternInstance.D = zzBottomPrices[0];

   patternInstance.ADateTime = zzTopDatetimes[1];
   patternInstance.BDateTime = zzBottomDatetimes[1];
   patternInstance.CDateTime = zzTopDatetimes[0];
   patternInstance.DDateTime = zzBottomDatetimes[0];

   return patternInstance;
}

//+-----------------------------------------------+
//| Monta o objeto Pattern Instance para calcular |
//| os Padrões Harmônicos Bearish com 4 pontos    |
//+-----------------------------------------------+
PATTERN_INSTANCE GetBearish4PointersPatternInstance( PATTERN_INDEX patternIndex ) {
   PATTERN_INSTANCE patternInstance;
   patternInstance.index = patternIndex;
   patternInstance.isBullish = false;
   patternInstance.isFourPoints = true;
   patternInstance.patternDescriptor = harmonicPatterns.patternsDescriptors[patternIndex];

   patternInstance.A = zzBottomPrices[1];
   patternInstance.B = zzTopPrices[1];
   patternInstance.C = zzBottomPrices[0];
   patternInstance.D = zzTopPrices[0];

   patternInstance.ADateTime = zzBottomDatetimes[1];
   patternInstance.BDateTime = zzTopDatetimes[1];
   patternInstance.CDateTime = zzBottomDatetimes[0];
   patternInstance.DDateTime = zzTopDatetimes[0];

   return patternInstance;
}


//---------------------------------------------------------------------------------
// Método para um desenho de fractal nos topos e fundos.
//---------------------------------------------------------------------------------
void criarIcone(string nome, double preco, datetime tempo, color cor, char codigoSimbolo) {
// https://www.mql5.com/en/docs/constants/objectconstants/wingdings
//char codigoSimbolo = 244;
   int tam = 1;

   icone.Create(0, nome, 0, tempo, preco, codigoSimbolo);

   icone.Color(cor);
   icone.Fill(true);
   icone.Width(tam);
//icone.Background(true);

}


// ---------------------------------------------------------------------
// Método responsável por remover o icone de todo do gráfico pelo nome |
// ---------------------------------------------------------------------
void removerIcone(string nome) {
   ObjectDelete(0, nome);
   ChartRedraw();
}



//---------------------------------------------------------------------------------
// Método para desenhar linha de tendência
//---------------------------------------------------------------------------------
void criarTriangulo(string nome, datetime t1, double p1, datetime t2, double p2,  datetime t3, double p3, color cor, ENUM_LINE_STYLE estilo = STYLE_SOLID, int largura = 1, bool isRaioDireita = false, bool isRaioEsquerda = false) {

   triangulo.Create(0, nome, 0, t1, p1, t2, p2, t3, p3);
   triangulo.Color(cor);
   triangulo.Style(estilo);
   triangulo.Fill(true);
   triangulo.Width(largura);

}


//--------------------------------------------
// Método para desenhar linha de tendência   |
//--------------------------------------------
void criarLinhaTendencia(string nomeLinha, datetime t1, double p1, datetime t2, double p2, color cor, ENUM_LINE_STYLE estilo = STYLE_SOLID, int largura = 1, bool isRaioDireita = false, bool isRaioEsquerda = false) {

   linhaTrend.Create(0, nomeLinha, 0, t1, p1, t2, p2);
   linhaTrend.Color(cor);
   linhaTrend.Style(estilo);
   linhaTrend.RayLeft(isRaioEsquerda);
   linhaTrend.RayRight(isRaioDireita);
   linhaTrend.Width(largura);


}

//-----------------------------------------------------------------------------------+
// Função responsável por abrir uma operação                                         |
//-----------------------------------------------------------------------------------+
void abrirOrdem(ENUM_ORDER_TYPE tipoOrdem, double preco, double volume, double sl = 0, double tp = 0, string coment = "") {

   bool result = false;
   preco = NormalizeDouble(preco, _Digits);
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);

// seta o identificador do robô
   trade.SetExpertMagicNumber(idRobo);
   trade.SetTypeFillingBySymbol(_Symbol);

   if(tipoOrdem == ORDER_TYPE_BUY) {

      result = trade.Buy(volume, _Symbol, preco, sl, tp, coment);

   } else if(tipoOrdem == ORDER_TYPE_SELL) {

      result = trade.Sell(volume, _Symbol, preco, sl, tp, coment);

   } else if(tipoOrdem == ORDER_TYPE_BUY_LIMIT) {

      result = trade.BuyLimit(volume, preco, _Symbol, sl, tp, ORDER_TIME_GTC, 0, coment);

   } else if(tipoOrdem == ORDER_TYPE_SELL_LIMIT) {

      result = trade.SellLimit(volume, preco, _Symbol, sl, tp, ORDER_TIME_GTC, 0, coment);

   }

// problema na requisição
   if(!result) {
      Print("Não foi possível abrir uma ordem de " + EnumToString(tipoOrdem), ". Código: ", trade.ResultRetcode());
   }

}

//+-------------------------------------------------------------+
// Função responsável por fechar uma ordem/posição no mercado   |
//+-------------------------------------------------------------+
void fecharTodasPosicoesRobo() {

   double saldo = 0;
   int totalPosicoes = PositionsTotal();

   for(int i = 0; i < totalPosicoes; i++) {

      string simbolo = PositionGetSymbol(i);
      ulong  magic = PositionGetInteger(POSITION_MAGIC);

      if(simbolo == _Symbol && magic == idRobo) {

         saldo = PositionGetDouble(POSITION_PROFIT);

         // fecha e verifica
         if(!trade.PositionClose(PositionGetTicket(i))) {
            Print("Erro ao fechar a negociação. Código: ", trade.ResultRetcode());
         } else {
            Print("Saldo: ", saldo);
         }
      }
   }
}


//----------------------------------------------------------------------+
//                                                                      |
// Função responsável por verificar se há posições abertas por tipo     |
//                                                                      |
//----------------------------------------------------------------------+
bool buscarPosicaoAbertasByTipo(ENUM_POSITION_TYPE tipoPosicaoBusca) {

   int totalPosicoes = PositionsTotal();
//Alert("POSICOES ABERTAS: " + totalPosicoes + " - Tipo posicao busca: " + EnumToString(tipoPosicaoBusca) );
   double lucroPosicao;

   for(int i = 0; i < totalPosicoes; i++) {

      // obtém o nome do símbolo a qual a posição foi aberta
      string simbolo = PositionGetSymbol(i);

      if(simbolo != "") {

         // id do robô
         ulong  magic = PositionGetInteger(POSITION_MAGIC);
         lucroPosicao = PositionGetDouble(POSITION_PROFIT);
         ENUM_POSITION_TYPE tipoPosicaoAberta = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
         // obtém o simbolo da posição
         string simboloPosicao = PositionGetString(POSITION_SYMBOL);

         // se é o robô e ativo em questão
         if(magic == idRobo && simboloPosicao == _Symbol) {

            // caso operação
            if(tipoPosicaoBusca == tipoPosicaoAberta) {

               //Alert("RETORNO POSICAO ABERTA: " + EnumToString(tipoPosicaoAberta) + " - ROBO: " + magic);
               //Alert("TEM VENDA");
               return true;
            }
         } // fim magic

      } else {
         PrintFormat("Erro quando recebeu a posição do cache com o indice %d." + " Error code: %d", i, GetLastError());
         ResetLastError();
      }

   } // fim for

   return false;

}

//----------------------------------------------------------------------+
// Método responsável por obter o histórico de negociação               |
//----------------------------------------------------------------------+
/*
void obterHistoricoNegociacaoRobo() {

   HistorySelect(0, TimeCurrent());
   uint     total = HistoryDealsTotal();
   ulong    ticket = 0;
   double   price, profit;
   datetime time;
   string   symbol;
   long     type, entry;

   for(uint i = 0; i < total; i++) {

      if((ticket = HistoryDealGetTicket(i)) > 0) {
         price = HistoryDealGetDouble(ticket, DEAL_PRICE);
         time  = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
         type  = HistoryDealGetInteger(ticket, DEAL_TYPE);
         entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         int magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
         string coment = HistoryDealGetString(ticket, DEAL_COMMENT);

         if( entry == DEAL_ENTRY_OUT && symbol == _Symbol && magic == idRobo  ) {

            Print("Ativo: ", symbol, " - Preço saída: ", price, " - Lucro: ", profit, " - Entry: ", entry  );
         }
      }
   }

} */

//----------------------------------------------------------------------+
// Método responsável por excluir todas as ordens pendentes             |
//----------------------------------------------------------------------+
bool excluirTodasOrdensPendentesRobo() {

   bool isOk = true;

// pecorre todas a ordens pendentes abertas
   for(int i = OrdersTotal() - 1 ; i >= 0; i--) {

      // seleciona a ordem pendente por seu índice
      if(ordensPendentes.SelectByIndex(i)) {

         // se a ordem pedente for do ativo monitorado e aberta pelo robô
         if(ordensPendentes.Symbol() == _Symbol  && ordensPendentes.Magic() == idRobo)
            if(!trade.OrderDelete(ordensPendentes.Ticket())) {
               Print("Erro ao excluir a ordem pendente ", ordensPendentes.Ticket(), ". Erro: ", GetLastError());
            }
      }
   }

   return isOk;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/*
void gravarArquivo() {

// PATH\\MQL5\\Files
   string nomeArquivo = "dadosCandle.csv";
   int fileHandle = FileOpen(nomeArquivo, FILE_READ | FILE_WRITE | FILE_CSV);

   if( fileHandle != INVALID_HANDLE ) {

      // copianos os candles e GRAVANDO
      MqlRates candles[];
      int totalCandles = CopyRates(_Symbol, _Period, 0, 100, candles);

      if( totalCandles > 0 ) {
         for(int i = 0; i < totalCandles; i++) {
            MqlRates cand = candles[i];
            string dadoGravar = cand.time + ";" + cand.open + ";" + cand.close;
            FileWrite(fileHandle,  dadoGravar); // escreve no buffer

            if( i == totalCandles - 1 ) {
               FileFlush(fileHandle); // grava no arquivo
            }
         }
         FileClose(fileHandle); // fecha o arquivo
      }
   }
} */
//+------------------------------------------------------------------+
