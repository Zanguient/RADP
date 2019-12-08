//+------------------------------------------------------------------+
//|                                                RoboHarmonico.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"


// Includes
#include <Trade\AccountInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <ChartObjects\ChartObjectsArrows.mqh>
#include <ChartObjects\ChartObjectsLines.mqh>
#include <ChartObjects\ChartObjectsFigures.mqh>
#include <Generic\Internal\CompareFunction.mqh>
#include <OptionScanner.mqh>

// Resources
#resource "\\Indicators\\fastzz.ex5";

//--- Identifica o Padrão
struct PATTERN_INSTANCE {
   int               patternBufferIndex;
   int               name;
   bool              bullish;
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

enum PATTERN_INDEX {
   BULLISH_GARTLEY = 0,
   BEARISH_GARTLEY,
   BULLISH_ABCD,
   BEARISH_ABCD
};

CAccountInfo infoConta;
CTrade trade;
CSymbolInfo ativoInfo;
COrderInfo ordensPendentes;
CChartObjectArrow topo, icone;
CChartObjectTrend linhaTrend;
CChartObjectTriangle triangulo;
OptionScanner optionScanner;

int idRobo = 1618033;

input int desvio = 25;
int input totalCopiarBuffer = 1000;

// Fastzz handler
int zzHandle;

// Fastzz buffers
double zzTopoBuffer[];
double zzFundoBuffer[];

// Date time buffer
datetime tempoCandleBuffer[];

int patternsCount = 0;

// Temporarily Arrays
double precoTopos[3];
double precoFundos[3];
datetime dataTopos[3];
datetime dataFundos[3];
PATTERN_INSTANCE patterns[100000];


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {

   zzHandle = iCustom(_Symbol, _Period, "::Indicators\\fastzz.ex5", desvio );

   if(zzHandle == INVALID_HANDLE) {
      Print("Falha ao criar o indicador ZigZag: ", GetLastError());
      return(INIT_FAILED);
   }

   // define para acessar como timeseries
   ArraySetAsSeries(zzTopoBuffer, true);
   ArraySetAsSeries(zzFundoBuffer, true);
   ArraySetAsSeries(tempoCandleBuffer, true);

   // ativo
   ativoInfo.Name( _Symbol );


   return(INIT_SUCCEEDED);

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   string X,A,B,C,D;

   for(int i=0; i < 100000; i++) {
      X = DoubleToString(patterns[i].X, 4);
      A = DoubleToString(patterns[i].A, 4);
      B = DoubleToString(patterns[i].B, 4);
      C = DoubleToString(patterns[i].C, 4);
      D = DoubleToString(patterns[i].D, 4);

      if (patterns[i].X != 0 && patterns[i].A != 0 && patterns[i].B != 0 && patterns[i].C != 0 && patterns[i].D != 0) {
         Print(X +"~~"+ A +"~~"+ B +"~~"+ C +"~~"+ D);
      }

   }
}

int totalBarrasAnt = 0;

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
// copia os topos
   if(CopyTime(_Symbol, _Period, 0, totalCopiarBuffer, tempoCandleBuffer) < 0 )  {
      Print("Erro ao copiar tempos: ", GetLastError());
      return;
   }

// copia os topos
   if(CopyBuffer(zzHandle, 0, 0, totalCopiarBuffer, zzTopoBuffer) < 0 )  {
      Print("Erro ao copiar dados dos topos: ", GetLastError());
      return;
   }

// copia os fundos
   if(CopyBuffer(zzHandle, 1, 0, totalCopiarBuffer, zzFundoBuffer) < 0 )  {
      Print("Erro ao copiar dados dos fundos: ", GetLastError());
      return;
   }

// Copia os topos e fundo para os arrays temporários
   getBottoms();
   getTops();

   PATTERN_INSTANCE patternInstance = getBullishGartleyPatternInstance();

   CreateZZTendencyLines();

   /*  bool isBullishGartley = isBullishGartley( patternInstance );

     if( isBullishGartley ) {
        createBullishGartleyGraphic( patternInstance );

        patterns[patternsCount] = patternInstance;
        patternsCount++;
        Print(patternInstance.X," ", patternInstance.A, " ",patternInstance.B, " ",patternInstance.C, " ",patternInstance.D, " ",patternInstance.XDateTime," ", patternInstance.ADateTime," ", patternInstance.BDateTime," ", patternInstance.CDateTime, " ", patternInstance.DDateTime);
        // COMPRA
        // optionScanner.GetMostTradedOptionOfAction(_Symbol);
        ativoInfo.Refresh(); // atualiza os dados do ativo
        double vol = ativoInfo.LotsMin();
        double stop = precoFundos[2];
        double takeProfit = precoTopos[0];

        bool isOrdemCompraAberta = buscarPosicaoAbertasByTipo( POSITION_TYPE_BUY );

        // abrirá apenas uma ordem de compra por vez
        if( !isOrdemCompraAberta ) {
           abrirOrdem(ORDER_TYPE_BUY, ativoInfo.Ask(), vol, stop, takeProfit, "GB");
        }

     }  */

   PATTERN_INSTANCE bullishABCD = GetBullishABCDPatternInstance();
   bool isBullishABCD = IsBullishABCD();
   if ( isBullishABCD ) {
      abrirOrdem(ORDER_TYPE_BUY, ativoInfo.Ask(), ativoInfo.LotsMin(), bullishABCD.D, bullishABCD.C, "Bullish ABCD");
      createBullishABCDTrendLines( bullishABCD );
   }
   
   IsBearishABCD();
}


//+------------------------------------------------------------------+
//| Verifica se é um Bullish Gartley                                 |
//+------------------------------------------------------------------+
bool isBullishGartley( PATTERN_INSTANCE &pattern ) {
   return (
             calculateBullishGartley( pattern )
             && DatetimeComparition5PointersPatterns
             (
                pattern.XDateTime,
                pattern.ADateTime,
                pattern.BDateTime,
                pattern.CDateTime,
                pattern.DDateTime
             )
             && !isPersistenceInstance( pattern )
          );
}

//+-----------------------------+
//| Verifica se é Bullish ABCD  |
//+-----------------------------+
bool IsBullishABCD() {
   PATTERN_INSTANCE pattern = GetBullishABCDPatternInstance();
   return (
             CalculateBullishABCD( pattern )
             && DatetimeComparition4PointersPatterns
             (
                pattern.ADateTime,
                pattern.BDateTime,
                pattern.CDateTime,
                pattern.DDateTime
             )
          );
}

//+-------------------------------+
//| Verifica se é um Bearish ABCD |
//+-------------------------------+
void IsBearishABCD() {
   PATTERN_INSTANCE pattern = GetBearishABCDPatternInstance();
   if (
             CalculateBearishABCD( pattern )
             && DatetimeComparition4PointersPatterns
             (
                pattern.ADateTime,
                pattern.BDateTime,
                pattern.CDateTime,
                pattern.DDateTime
             )
      ) {
         Print("Deu BearishABCD");
         createBullishABCDTrendLines( pattern );
      }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isPersistenceInstance( PATTERN_INSTANCE &patternInstance  ) {
   if( patternsCount == 0 ) return false;

   PATTERN_INSTANCE previouPattern = patterns[ patternsCount - 1 ];

   return ( patternInstance.XDateTime == previouPattern.XDateTime
            && patternInstance.ADateTime ==  previouPattern.ADateTime
            && patternInstance.BDateTime ==  previouPattern.BDateTime
            && patternInstance.CDateTime == previouPattern.CDateTime
            && (patternInstance.DDateTime == previouPattern.DDateTime
                || patternInstance.DDateTime != previouPattern.DDateTime )
          );
}




//+------------------------------------------------------------------+
//| Cria as linhas de tendências dos topos e fundos do Fast ZZ       |
//+------------------------------------------------------------------+
void CreateZZTendencyLines() {
   removerIcone("linhaTopo");
   datetime dt_top1, dt_top2, dt_bottom1, dt_bottom2;
   double pc_top1, pc_top2, pc_bottom1, pc_bottom_2;

   dt_top1 = dataTopos[0];
   dt_top2 = dataTopos[2];
   dt_bottom1 = dataFundos[0];
   dt_bottom2 = dataFundos[2];

   pc_top1 = precoTopos[0];
   pc_top2 = precoTopos[2];
   pc_bottom1 = precoFundos[0];
   pc_bottom_2 = precoFundos[2];

   removerIcone("linhaTopo");
   criarLinhaTendencia("linhaTopo", dt_top2, pc_top2, dt_top1, pc_top1, clrPurple, STYLE_DASH, 1, true, false);

   removerIcone("linhaFundo");
   criarLinhaTendencia("linhaFundo", dt_bottom2, pc_bottom_2, dt_bottom1, pc_bottom1, clrOrange, STYLE_DASH, 1, true, false);
}


//+---------------------------------------------------------------+
//| Cria uma instância do objeto para calcular o Bullish Gartley  |
//+---------------------------------------------------------------+
PATTERN_INSTANCE getBullishGartleyPatternInstance() {
   PATTERN_INSTANCE patternInstance;
   patternInstance.name = BULLISH_GARTLEY;
   patternInstance.X = precoFundos[2];
   patternInstance.A = precoTopos[1];
   patternInstance.B = precoFundos[1];
   patternInstance.C = precoTopos[0];
   patternInstance.D = precoFundos[0];
   patternInstance.XDateTime = dataFundos[2];
   patternInstance.ADateTime = dataTopos[1];
   patternInstance.BDateTime = dataFundos[1];
   patternInstance.CDateTime = dataTopos[0];
   patternInstance.DDateTime = dataFundos[0];

   return patternInstance;
}

//+------------------------------------------------------------------+
//| Cria uma instância do objeto para calcular o Bearish Gartley     |
//+------------------------------------------------------------------+
PATTERN_INSTANCE GetBearishGartleyPatternInstance() {
   PATTERN_INSTANCE patternInstance;

   patternInstance.patternBufferIndex = patternsCount;
   patternInstance.X = precoTopos[2];
   patternInstance.A = precoFundos[1];
   patternInstance.B = precoTopos[1];
   patternInstance.C = precoFundos[0];
   patternInstance.D = precoTopos[0];
   patternInstance.XDateTime = dataTopos[2];
   patternInstance.ADateTime = dataFundos[1];
   patternInstance.BDateTime = dataTopos[1];
   patternInstance.CDateTime = dataFundos[0];
   patternInstance.DDateTime = dataTopos[0];

   return patternInstance;
}

//+------------------------------------------------------------+
//| Cria uma instância do objeto para calcular o Bullish ABCD  |
//+------------------------------------------------------------+
PATTERN_INSTANCE GetBullishABCDPatternInstance() {
   PATTERN_INSTANCE patternInstance;

   patternInstance.name = BULLISH_ABCD;

   // VALORES
   patternInstance.A = precoTopos[1];
   patternInstance.B = precoFundos[1];
   patternInstance.C = precoTopos[0];
   patternInstance.D = precoFundos[0];

   // DATETIMES
   patternInstance.ADateTime = dataTopos[1];
   patternInstance.BDateTime = dataFundos[1];
   patternInstance.CDateTime = dataTopos[0];
   patternInstance.DDateTime = dataFundos[0];

   return patternInstance;
}

//+--------------------------------+
//| Calcula o Padrão Bullish ABCD  |
//+--------------------------------+
bool CalculateBullishABCD( PATTERN_INSTANCE &pattern ) {
   double A, B, C, D, ABMin, ABMax, CDMin, CDMax;

   A = pattern.A;
   B = pattern.B;
   C = pattern.C;
   D = pattern.D;

   /*
      Carney (1999, p. 118):
      I consider the completion of a exact AB = CD
      a minimun requirement before entering a trade.
   */
   if( ( A - B ) == ( C - D ) ) {

      ABMin = B + ( ( A - B ) * .618 );
      ABMax = B + ( ( A - B ) * .786 );

      if ( C >= ABMin && C <= ABMax ) {

         CDMin = C - ( ( C - B ) * 1.618 );
         CDMax = C - ( ( C - B ) * 1.27 );

         if ( D >= CDMin && D <= CDMax ) {
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
bool CalculateBearishABCD( PATTERN_INSTANCE &pattern ) {
   double A, B, C, D, ABMin, ABMax, CDMin, CDMax;

   A = pattern.A;
   B = pattern.B;
   C = pattern.C;
   D = pattern.A;

   if ( ( B - A )  == ( D - C ) ) {

      ABMin = A + ( ( B - A ) * .618 );
      ABMax = A + ( ( B - A ) * .786 );

      if ( C >= ABMin && C <= ABMax ) {

         CDMin = C + ( ( B - A ) * 1.272 );
         CDMax = C + ( ( B - A ) * 1.618 );

         if ( C >= CDMin && C <= CDMax ) {
            return true;
         }
      }
   }
   return false;
}


//+------------------------------------------------------------+
//| Cria uma instância do objeto para calcular o Bearish ABCD  |
//+------------------------------------------------------------+
PATTERN_INSTANCE GetBearishABCDPatternInstance() {
   PATTERN_INSTANCE patternInstance;

   patternInstance.patternBufferIndex = patternsCount;

   // VALORES
   patternInstance.A = precoFundos[1];
   patternInstance.B = precoTopos[1];
   patternInstance.C = precoFundos[0];
   patternInstance.D = precoTopos[0];

   // DATETIMES
   patternInstance.ADateTime = dataFundos[1];
   patternInstance.BDateTime = dataTopos[1];
   patternInstance.CDateTime = dataFundos[0];
   patternInstance.DDateTime = dataTopos[0];

   return patternInstance;
}

//+-----------------------------------+
//| Cria a figura do Bullish Gartey   |
//+-----------------------------------+
void CreateBullishGartleyGraphic(PATTERN_INSTANCE &pattern) {
   // Cria dois triangulos que representam o padrão
   criarTriangulo("T-XAC "+ TimeToString(pattern.XDateTime), pattern.XDateTime, pattern.X, pattern.ADateTime, pattern.A, pattern.BDateTime, pattern.B, clrLightGreen, STYLE_SOLID, 1, false, false);
   criarTriangulo("T-BCD "+ TimeToString(pattern.CDateTime), pattern.BDateTime, pattern.B, pattern.CDateTime, pattern.C, pattern.DDateTime, pattern.D, clrLightGreen, STYLE_SOLID, 1, false, false);

}


//+------------------------------------------------------------------+
//| Método que coloca os três últimos topos no array temporário      |
//+------------------------------------------------------------------+
void getTops() {
   int tamVet = ArraySize ( zzTopoBuffer );
   int nrTopo = 0;
   for( int i = 0; i < tamVet; i++  ) {

      if( zzTopoBuffer[i] != 0 ) {
         if( nrTopo == 0 ) {

            precoTopos[nrTopo] = zzTopoBuffer[i];
            dataTopos[nrTopo] = tempoCandleBuffer[i];

         } else if( nrTopo == 1 ) {

            precoTopos[nrTopo] = zzTopoBuffer[i];
            dataTopos[nrTopo] = tempoCandleBuffer[i];

         } else if( nrTopo == 2 ) {

            precoTopos[nrTopo] = zzTopoBuffer[i];
            dataTopos[nrTopo] = tempoCandleBuffer[i];
            break;

         }
         nrTopo++;
      }

   }
}

//+------------------------------------------------------------------+
//| Método que coloca os três últimos fundos no array temporário     |
//+------------------------------------------------------------------+
void getBottoms() {
   int tamVet = ArraySize ( zzFundoBuffer );
   int nrFundo = 0;
   for( int i = 0; i < tamVet; i++  ) {

      if( zzFundoBuffer[i] != 0 ) {
         if( nrFundo == 0 ) {

            precoFundos[nrFundo] = zzFundoBuffer[i];
            dataFundos[nrFundo] = tempoCandleBuffer[i];

         } else if( nrFundo == 1 ) {

            precoFundos[nrFundo] = zzFundoBuffer[i];
            dataFundos[nrFundo] = tempoCandleBuffer[i];


         } else if( nrFundo == 2 ) {

            precoFundos[nrFundo] = zzFundoBuffer[i];
            dataFundos[nrFundo] = tempoCandleBuffer[i];
            break;
         }
         nrFundo++;
      }

   } // fim for fundo para obter apenas os dois últimos fundos mais atuais
}


//-------------------------------------------------
// Método para calcular/detectar Gartley Bullish  |
//-------------------------------------------------
bool calculateBullishGartley( PATTERN_INSTANCE &pattern ) {
   double X,A,B,C,D;

   X = pattern.X;
   A = pattern.A;
   B = pattern.B;
   C = pattern.C;
   D = pattern.D;

   double AB1 = (A - X) * 0.618;
   double AB2 = (A - X) * 0.5;

   if(  B >= (A - AB1) && B <= ( A - AB2)  ) {
      // Print("XABLAU... B");

      double BC1 = ( A - B ) * 0.618;
      double BC2 = ( A - B ) * 0.886;

      if(  C >= (B + BC1) && C <= (B + BC2) ) {

         double XA1 = (A - X) * 0.986;
         double XA2 = (A - X) * 0.786;
         if( D >= (A - XA1) && D <= (A - XA2)  ) {
            return true;
         }
      }

   }

   return false;

}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool calculateBearishGartley( PATTERN_INSTANCE &pattern ) {
   return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void createBullishABCDTrendLines( PATTERN_INSTANCE &pattern ) {
   double A,B,C,D;
   datetime ADatetime, BDatetime, CDatetime, DDatetime;

   A = pattern.A;
   B = pattern.B;
   C = pattern.C;
   D = pattern.D;

   ADatetime = pattern.ADateTime;
   BDatetime = pattern.BDateTime;
   CDatetime = pattern.CDateTime;
   DDatetime = pattern.DDateTime;

   criarTriangulo("ABC " + TimeToString(ADatetime), ADatetime, A, BDatetime, B, CDatetime, C, clrLightGreen, STYLE_SOLID, 1, false, false);
   criarTriangulo("BCD " + TimeToString(BDatetime), BDatetime, B, CDatetime, C, DDatetime, D, clrBlueViolet, STYLE_SOLID, 1, false, false);

}


/*
   https://www.mql5.com/pt/docs/standardlibrary/generic/compare

   int Compare(
      const datetime  x,     // primeiro valor
      const datetime  y      // segundo valor
   );

   Valor de retorno

   Retorna o número que expressa a razão entre os dois valores comparados:

   resultado inferior a zero – x é menor que y (x<y)
   resultado igual a zero – x igual a y (x=y)
   resultado superior a zero – x maior que y (x>y)
*/

//+-----------------------------------------------------------------+
//|  Compara os DateTimes dos padrões que possuem 4 pontos seguem a |
//|  uma sequência cronológica.                                     |
//+-----------------------------------------------------------------+
bool DatetimeComparition4PointersPatterns(datetime A, datetime B, datetime C, datetime D) {
   return (
             Compare( B, A ) > 0
             && Compare( C, B ) > 0
             && Compare( D, C ) > 0
          );
}

//+------------------------------------------------------------------+
//|  Compara os DateTimes dos padrões que possuem 5 pontos seguem a |
//|  uma sequência cronológica.                                     |
//+------------------------------------------------------------------+
bool DatetimeComparition5PointersPatterns(datetime X, datetime A, datetime B, datetime C, datetime D) {
   return (
             Compare( A, X ) > 0
             && Compare( B, A ) > 0
             && Compare( C, B ) > 0
             && Compare( D, C ) > 0
          );
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

   } else if (tipoOrdem == ORDER_TYPE_SELL) {

      result = trade.Sell(volume, _Symbol, preco, sl, tp, coment);

   } else if(tipoOrdem == ORDER_TYPE_BUY_LIMIT) {

      result = trade.BuyLimit(volume, preco, _Symbol, sl, tp, ORDER_TIME_GTC, 0, coment);

   } else if(tipoOrdem == ORDER_TYPE_SELL_LIMIT) {

      result = trade.SellLimit(volume, preco, _Symbol, sl, tp, ORDER_TIME_GTC, 0, coment);

   }

// problema na requisição
   if(!result) {
      Print("Não foi possível abrir uma ordem de " + EnumToString(tipoOrdem), ". Código: ", trade.ResultRetcode() );
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

      if( simbolo == _Symbol && magic == idRobo ) {

         saldo = PositionGetDouble(POSITION_PROFIT);

         // fecha e verifica
         if(!trade.PositionClose(PositionGetTicket(i))) {
            Print("Erro ao fechar a negociação. Código: ", trade.ResultRetcode() );
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
bool excluirTodasOrdensPendentesRobo( ) {

   bool isOk = true;

// pecorre todas a ordens pendentes abertas
   for(int i = OrdersTotal() - 1 ; i >= 0; i--) {

      // seleciona a ordem pendente por seu índice
      if( ordensPendentes.SelectByIndex(i) ) {

         // se a ordem pedente for do ativo monitorado e aberta pelo robô
         if(ordensPendentes.Symbol() == _Symbol  && ordensPendentes.Magic() == idRobo)
            if (!trade.OrderDelete( ordensPendentes.Ticket() ) ) {
               Print("Erro ao excluir a ordem pendente ", ordensPendentes.Ticket(), ". Erro: ", GetLastError() );
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
