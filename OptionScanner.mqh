//+------------------------------------------------------------------+
//|                                                OptionScanner.mqh |
//|                                                     João Salomão |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "João Salomão"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class OptionScanner
  {
private:
   int               symbolsIndex;
   bool              CompararDatasIgualOuMaiorMesAno(datetime data1,datetime data2);
   bool              CompararDatasMesAnoDia(datetime data1,datetime data2);
public:
                     OptionScanner();
                    ~OptionScanner();
   void              GetMostTradedOptionOfAction(string symbol);
   string            GetMostTradedOptionOfTheDay();
   void              ShowActiveOptions();

  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
OptionScanner::OptionScanner()
  {
   symbolsIndex = SymbolsTotal(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
OptionScanner::~OptionScanner()
  {

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OptionScanner::GetMostTradedOptionOfAction(string symbol)
  {
   string activeName = StringSubstr(symbol,0,4);

// Nome e volume da opção mais negociada do dia.
   double maxTotalVolumeOfDay=0;
   string mostTradedOptionName;

// Option informations
   string optionName;
   string path;
   double bid;
   double ask;
   double priceOfLastTrade;
   datetime dateAndHourOfLastTrade;
   datetime endNegotiationDate;
   double totalVolumeOfDay;
   int count= 0;
   for(int i=0; i <100 ; i++)
     {
      // Nome do ativo
      optionName=SymbolName(i,false);

      // coloca o simbolo no janela Observação do Mercado (CTRL + M)
      if(!SymbolSelect(optionName,true))
        {
         SymbolSelect(optionName,true);
         // aguarda um tempo para que a opção apareca na janela Observação do Mercado
         // senão não é possível ler os dados (e.g., preço, volume, ....)
         Sleep(200);
        }

      path=SymbolInfoString(optionName,SYMBOL_PATH);
      // se for opção
      if(StringFind(path,"BOVESPA\OPCOES")>-1)
        {
         // se for uma opção do ativo
         if(StringSubstr(optionName,0,4)==activeName)
           {
            // pega as informações da opção
            bid = SymbolInfoDouble(optionName, SYMBOL_BID);
            ask = SymbolInfoDouble(optionName, SYMBOL_ASK);
            priceOfLastTrade=SymbolInfoDouble(optionName,SYMBOL_LAST);
            dateAndHourOfLastTrade=(datetime)SymbolInfoInteger(optionName,SYMBOL_TIME);
            endNegotiationDate=(datetime)SymbolInfoInteger(optionName,SYMBOL_EXPIRATION_TIME);
            totalVolumeOfDay=SymbolInfoDouble(optionName,SYMBOL_SESSION_VOLUME);
            Print(totalVolumeOfDay);
            // FILTROS: mostrar apenas aquelas que está tendo negociação, com volume e com expiração no mês corrente
            if(bid!=0 && ask!=0 && priceOfLastTrade!=0 && totalVolumeOfDay!=0
               && CompararDatasIgualOuMaiorMesAno(TimeCurrent(),dateAndHourOfLastTrade)
               && CompararDatasIgualOuMaiorMesAno(TimeCurrent(),endNegotiationDate)
              )
              {
               if(totalVolumeOfDay>maxTotalVolumeOfDay)
                 {
                  Print("É maior que o atual");
                  maxTotalVolumeOfDay=totalVolumeOfDay;
                  mostTradedOptionName=optionName;
                 }
              }
           }
        }
      // remove o simbolo no janela Observação do Mercado (senão ficaria com milhares!!)
      SymbolSelect(optionName,false);
     }
   Print(">>>>>>>>>>> "+mostTradedOptionName+" | Count "+count);
  }
  
  
void OptionScanner::ShowActiveOptions()
{
   // Para cada ativo negociado no mercado ...
   
   for ( int i = 0 ; i < SymbolsTotal(false) ; i++ )
   {
      // Obtem o ticker do ativo
       
      string  symbolName = SymbolName(i,false);
      SymbolSelect(symbolName, true);
      Sleep(500);
      
      // Se os 4 primeiros caracteres do ticker corresponderem ao ativo subjacente desejado
      // e o ativo for uma opcao (valor do strike diferente de zero),
      // imprime informacoes da opcao
      
      if ( StringSubstr(symbolName,0,4) == "VALE" && SymbolInfoDouble(symbolName,SYMBOL_OPTION_STRIKE) > 0 ) 
      {
         PrintFormat
         (
            "%10s - %4s  Vencimento: %s  Strike: %5.2f  Tipo: %s  Descricao: <%s>" , 
            symbolName ,
            StringSubstr ( EnumToString ( (ENUM_SYMBOL_OPTION_RIGHT) SymbolInfoInteger ( symbolName , SYMBOL_OPTION_RIGHT ) ) , 20 ),
            TimeToString ( SymbolInfoInteger ( symbolName , SYMBOL_EXPIRATION_TIME ), TIME_DATE ), 
            SymbolInfoDouble  ( symbolName , SYMBOL_OPTION_STRIKE ),
            StringSubstr ( EnumToString ( (ENUM_SYMBOL_OPTION_MODE) SymbolInfoInteger ( symbolName , SYMBOL_OPTION_MODE ) ) , 19 ),
            SymbolInfoString  ( symbolName , SYMBOL_DESCRIPTION )
         );
      }
      SymbolSelect(symbolName, false);
   }
}
//+---------------------------------------------------------------------------------------+
//| Método que compara duas datas se são maiores ou iguais em consideração o mês e o ano. |
//+---------------------------------------------------------------------------------------+
static bool OptionScanner::CompararDatasIgualOuMaiorMesAno(datetime data1,datetime data2)
  {

   MqlDateTime dataEstrutura1;
   TimeToStruct(data1,dataEstrutura1);

   MqlDateTime dataEstrutura2;
   TimeToStruct(data2,dataEstrutura2);

   if(dataEstrutura2.mon>=dataEstrutura1.mon && dataEstrutura2.year>=dataEstrutura1.year)
     {
      return true;
     }

   return false;

  }
//+------------------------------------------------------------------------+
//| Método que compara duas data levando em consideração o mês, ano e dia. |
//+------------------------------------------------------------------------+
static bool OptionScanner::CompararDatasMesAnoDia(datetime data1,datetime data2)
  {

   MqlDateTime dataEstrutura1;
   TimeToStruct(data1,dataEstrutura1);

   MqlDateTime dataEstrutura2;
   TimeToStruct(data2,dataEstrutura2);

   if(dataEstrutura1.day==dataEstrutura2.day && dataEstrutura1.mon==dataEstrutura2.mon && dataEstrutura1.year==dataEstrutura2.year)
     {
      return true;
     }

   return false;

  }
//+------------------------------------------------------------------+
