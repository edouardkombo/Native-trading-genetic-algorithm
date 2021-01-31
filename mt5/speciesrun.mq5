
#include "../../Include/Math/Alglib/alglib.mqh"
CAlglib           Alg;
CHighQualityRandStateShell state;

#include <Files\File.mqh>

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CFile file;
int backbars=25;
int numinputs;//7 indicadors values*12 back bars=35 + 7(trading)*2(status-sell-buy)=14 -->Total=56
int size_out1=35;//2 por ahora añadir mas mas adelantes
int size_out2=35;//2 por ahora ñadir mas mas afelante
int size_out3=35;//2 por ahora ñadir mas mas afelante
int out;
bool primero=true;
static datetime    prevtime=0;
int numbarshistory=0;
double profitbuy[][5];
double profitsell[][5];

double volbuy[][5];
double volsell[][5];


bool stoptrading=false;

double tmpbadresult=0;
int maxorders=200;
int maxlotglobal=5;

double dummyStartP=10000000;
double dummyStartV=10000;

double maxlot=0.1;
double minlot=0.01;

double orderscount=0;
//########
string symb[]={"EURUSD","GBPUSD","AUDUSD","USDJPY","USDCAD"};



int hand_fast[];
int hand_slow[];

//string symb[]={"EURUSD"};
input int Slow=14;
input int Fast=5;
input int dummy=0;//0....10000000 
input bool real=false;

CTrade trade;
CPositionInfo pinfo;

class CNet
  {  
  private:
   double damepercept(int pid,double &values[]);
  public:      
   double xvalues[];
   int numinput;
   int numouts;
   int               CNet_OnInit(int inputs,int outputs);
   double applycalcs(double &values[],double &percepts[]);
   
  };
double CNet::damepercept(int pid,double &values[]){

   double ret=0;
   for(int x=0;x<numinput;x++){
      double w=xvalues[(pid*numinput)+x];
      double a=values[x];
      ret+=(w*a);
   }
   return ret;
}
double CNet::applycalcs(double &values[],double &percepts[]){  
   double ret=0;
   //en values tiene size de inputs i la funcion devuelve percetps
   ArrayResize(percepts,numouts);
   ArrayInitialize(percepts,0);
   
   for (int x=0;x<numouts;x++){
     percepts[x]=damepercept(x,values);
   }
      
   return ret;
}
int CNet::CNet_OnInit(int inputs,int outputs){
   
   numinput=inputs;
   numouts=outputs;
   ArrayResize(xvalues,inputs*outputs);
   return 0;
}

CNet net1;
CNet net2;
CNet net3;
CNet out1;



//how many numbers need and how many bits need read
//49*10 + 10*5 + 5*7 = Total numbers need optimize by GA
//each number is 4 bytes (int representation) each byte 8 bits
//then need optimize 8bit*4bytes*TOTAL NUMBERS= total bits need read on file and need optimize


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int step=-1;//0....10000000 
int handle;


double allints[];
int TOTALINTNUMBERS=0;
int TOTALBITS=0;
int BinaryToInt(string binary){  // With thanks, concept from http://www.cplusplus.com/forum/windows/30135/ (though the code on that page is faulty afaics)
  int out=0;
  if(StringLen(binary)==0){return(0);}
  for(int i=0;i<StringLen(binary);i++){
    if(StringSubstr(binary,i,1)=="1"){
      out+=int(MathPow(2,StringLen(binary)-i-1));
    }else{
      if(StringSubstr(binary,i,1)!="0"){
        
      }
    }
  }
  return(out);
}

bool startpreproces(int filehnd){
   TOTALINTNUMBERS=(numinputs*size_out1)+(size_out1*size_out2)+(size_out2*size_out3)+(size_out3*out);
   //TOTALINTNUMBERS=(numinputs*size_out1)+(size_out1*size_out2)+(size_out2*out);
   TOTALBITS=TOTALINTNUMBERS*8*4;
   ArrayResize(allints,TOTALINTNUMBERS);
   int steps=8*4;
   int tmp=0;
   string tmpstr="";
   int numint=0;
   string allstring="";
   while(!FileIsEnding(filehnd)){
      allstring+=FileReadString(filehnd);      
   }
//   printf (allstring);
   if(StringFind(allstring,"done",0)>=0){
      return false; //fichero procesado
   }
   
   int leng=StringLen(allstring);
   string sep=",";
   ushort u_sep;                  // código del separador
   string result[];               // array para obtener cadenas
   //--- obtenemos el código del separador
   u_sep=StringGetCharacter(sep,0);
   string outstr[];
   StringSplit(allstring,u_sep,outstr);
   int len2=ArraySize(outstr);
   /*for (int x=0;x<len2-2;x++){
      
      if (outstr[x]=="true"){
         tmpstr+=(string)1;
      }else{
         tmpstr+=(string)0;
      }
      tmp++;   
      if (tmp>=steps){
         tmp=0;
         double xtmp=BinaryToInt(tmpstr);
         xtmp=xtmp/2147483647;
         allints[numint]=xtmp;         
         numint++;
         tmpstr="";
      }
   }  */
   
   for (int x=0;x<len2-2;x++){
                              
         //tmp=0;
         //double xtmp=BinaryToInt(tmpstr);
         //xtmp=xtmp/2147483647;
         if (outstr[x]!=""){
            allints[numint]=((double)outstr[x]);         
            numint++;
         }else{
            printf("empty");
         }
         //tmpstr="";
      
   }  
   //BIEN! en allints tenemos todos los pesos solo tenemos que ponerlos ordenadors en la matriz coorrecta de cada layer
   
   
   net1.CNet_OnInit(numinputs,size_out1);   
   net2.CNet_OnInit(size_out1,size_out2);
   net3.CNet_OnInit(size_out2,size_out3);
   out1.CNet_OnInit(size_out3,out);
   tmp=0;
   //refill all weigth from this layer
   for (int x=0;x<(numinputs*size_out1);x++){
      net1.xvalues[x]=allints[tmp];      
      tmp++;
   }
   for (int x=0;x<(size_out1*size_out2);x++){
      net2.xvalues[x]=allints[tmp];      
      tmp++;
   }
   for (int x=0;x<(size_out2*size_out3);x++){
      net3.xvalues[x]=allints[tmp];      
      tmp++;
   }
   for (int x=0;x<(size_out3*out);x++){
      out1.xvalues[x]=allints[tmp];      
      tmp++;
   }
   return true;
}
bool readTrueFile(){
string filter="*.best";
   string file_name;
   long search_handle=FileFindFirst(filter,file_name,FILE_COMMON);
//--- check if FileFindFirst() executed successfully

   if(search_handle!=INVALID_HANDLE)
     {         
         int filehnd=FileOpen(file_name,FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON);
         //cerramos el 
         if (filehnd!=INVALID_HANDLE){
            
            if (startpreproces(filehnd)){
               //nothing
               string results[];
               StringSplit(file_name,'.',results);
               step=StringToInteger(results[0]);       
               //FileSeek(filehnd,0,SEEK_SET);
               //FileWrite(filehnd,"done");
               //FileFlush(filehnd);
               FileClose(filehnd);                                        
                              
            
               //while(FileIsExist(file_name,FILE_COMMON)){                            
                  //FileDelete(file_name,FILE_COMMON);
                //  FileMove(file_name,FILE_COMMON,(string)step+"",FILE_COMMON);
               //}
            //hay qu eeliminarlo! 
               return true;
            }else{
               FileClose(filehnd);       
               return false;
            }
            
                             
         }         
     }
     return false;
}
bool readfile(){
   //cogemos un archivo aleatorio
   string filter="*.ttt";
   string file_name;
   long search_handle=FileFindFirst(filter,file_name,FILE_COMMON);
//--- check if FileFindFirst() executed successfully

   if(search_handle!=INVALID_HANDLE)
     {         
         int filehnd=FileOpen(file_name,FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON);
         //cerramos el 
         if (filehnd!=INVALID_HANDLE){
            
            if (startpreproces(filehnd)){
               //nothing
               string results[];
               StringSplit(file_name,'.',results);
               step=StringToInteger(results[0]);       
               FileSeek(filehnd,0,SEEK_SET);
               FileWrite(filehnd,"done");
               //FileFlush(filehnd);
               FileClose(filehnd);                                        
                              
            
               while(FileIsExist(file_name,FILE_COMMON)){                            
                  FileDelete(file_name,FILE_COMMON);
                //  FileMove(file_name,FILE_COMMON,(string)step+"",FILE_COMMON);
               }
            //hay qu eeliminarlo! 
               return true;
            }else{
               FileClose(filehnd);       
               return false;
            }
            
                             
         }         
     }
     return false;
}
bool canstart(){
//cogemos un archivo disponible i lo leemos
   /*while(!readfile()){
   
      Sleep(200);
   } */
   //seguimos
   if (!real){
      if(readfile()){
      return true;
      }
   }else{
      readTrueFile();
      return true;
   }
   
   int num=0;
   int def=1/num;
   return false;
}
bool cantrade=false;

int maxtrades=6;


double selllothisto[][5]; //50 * 6 * 5
double buylothisto[][5]; //50 * 6 * 5

double sellprofithisto[][5]; //50 * 6 * 5
double buyprofithisto[][5]; //50 * 6 * 5

int barstotals=50;


int OnInit()
  {

   numinputs=(5*backbars)+(ArraySize(symb)*2);
   
   out=40;
   
   
      primero=false;
      
      cantrade=canstart();
      
   
   //adebug read all bytes
   //ExpertRemove();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
  {

      
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+


double OnTester()
{

   
  return (TesterStatistics(STAT_PROFIT))*(TesterStatistics(STAT_SHARPE_RATIO));
}





//#######

void OnTick()
  {
//---
   //le paso la variable positions?
   //symbolo lote y profit? maximo 50 posiciones abiertas?
   
      return;
      if (!cantrade)return;
      if (primero){
         primero=false;
         for (int x=0;x<ArraySize(symb);x++){
            trade.Sell(0.01,symb[x]);
            trade.Buy(0.01,symb[x]);            
         }
         return;
      }
//NEW STRATEGY      

      if (!real){
            
         if (stoptrading)return;
         double tmppos=0;
         double tmpvol=0;
         for (int x=0;x<ArraySize(symb);x++){
            tmppos+=CountPosition(POSITION_TYPE_BUY,symb[x])+CountPosition(POSITION_TYPE_SELL,symb[x]);
            tmpvol+=CountVolume(POSITION_TYPE_BUY,symb[x])+CountVolume(POSITION_TYPE_SELL,symb[x]);
         }
         if (tmppos>maxorders || tmpvol>maxlotglobal){
         //if (tmppos>maxorders){
            docloseall();
            tmpbadresult=-tmpvol*tmppos*-1;
            tmpbadresult=-99999999;
            stoptrading=true;
         }
         
         
      }
      
      
      if(iTime(_Symbol,Period(),0)==prevtime)
      return;
      
      prevtime=iTime(_Symbol,Period(),0);
      
      
      //closealloldposition();
      
      ArrayResize(profitbuy,numbarshistory+1);
      ArrayResize(profitsell,numbarshistory+1);
      
      ArrayResize(volbuy,numbarshistory+1);
      ArrayResize(volsell,numbarshistory+1);
      
      for (int x=0;x<ArraySize(symb);x++){
         profitbuy[numbarshistory][x]=getProfits(POSITION_TYPE_BUY,symb[x]);
         profitsell[numbarshistory][x]=getProfits(POSITION_TYPE_SELL,symb[x]);
         
         volbuy[numbarshistory][x]=getVolums(POSITION_TYPE_BUY,symb[x]);
         volsell[numbarshistory][x]=getVolums(POSITION_TYPE_SELL,symb[x]);
         orderscount+=volbuy[numbarshistory][x]+volsell[numbarshistory][x];
      }
      numbarshistory++;
      
      double ind1[];// indicator plus trades values      
      double ind2[];//output ind for first net
      double ind3[];//output ind for sec net;
      double ind4[];//output ind for sec net;
      double outs[];//siganles >0 buy <0sell    
      
      ArrayResize(ind1,4*backbars*ArraySize(symb));
      int cta=0;
      for (int x=numbarshistory-1;x>=numbarshistory-backbars;x--){
         if (x<=0){
            for (int y=0;y<ArraySize(symb);y++){
               ind1[cta]=1; //profitbu inc
               cta++;
               ind1[cta]=1;
               cta++;
               ind1[cta]=1;
               cta++;
               ind1[cta]=1;
               cta++;
            }
         }else{
            for (int y=0;y<ArraySize(symb);y++){
               ind1[cta]=profitbuy[x][y]/profitbuy[x-1][y];
               cta++;
               ind1[cta]=profitsell[x][y]/profitsell[x-1][y];
               cta++;
               /*ind1[cta]=volbuy[x][y]/volbuy[x-1][y];
               cta++;
               ind1[cta]=volsell[x][y]/volsell[x-1][y];*/
               ind1[cta]=volbuy[x][y];
               cta++;
               ind1[cta]=volsell[x][y];
               cta++;
               
            }
         }
         
      }
      
      //apply networks calcs
      net1.applycalcs(ind1,ind2);
      net2.applycalcs(ind2,ind3);
      net3.applycalcs(ind3,ind4);
      out1.applycalcs(ind4,outs);
      
      //bit1 -1/+1 close buy false-true
      //bit2 -1/+1 close sell false-true
      //bit3 lotclose buy
      //bit4 lotclose sell
      
      //bit1 -1/+1 trade buy false-true
      //bit2 -1/+1 trade sell false-true
      //bit3 lot buy
      //bit4 lot sell
      int symbid=0;
      
      for (int x=0;x<(ArraySize(symb)*8);x+=8){      
         
         if (outs[x]>0){
            //need close lotbuy outs[x+1]
            printf("CLOSE1");
            close(POSITION_TYPE_BUY,outs[x+1],symb[symbid]);
         }   
         if (outs[x+2]>0){
            //need close lotsell outs[x+3]
            printf("CLOSE2");
            close(POSITION_TYPE_SELL,outs[x+3],symb[symbid]);
         }   
         if (outs[x+4]>0){
            //need open lot buy outs[x+5]
            printf("OPEN1");
            open(POSITION_TYPE_BUY,outs[x+5],symb[symbid]);
         }
         if (outs[x+6]>0){
            //need open lot sell outs[x+7]
            printf("OPEN2");
            open(POSITION_TYPE_SELL,outs[x+7],symb[symbid]);
         }
                  
         symbid++;                        
      }
      //trading by outs outstrategy
      
      
      

  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void close(ENUM_POSITION_TYPE type,double lot,string sym){
   
   if( CountVolume(type,sym)==0){
    //sino hay nada que cerrar salimos
     return;
   }else if (CountVolume(type,sym)<lot){
      //cierre total
      printf("CIERRE TOTAL");
      closetypesym(type,sym);
   }else{
      //sino es cierre total
      printf("CIERRE PARCIAL");
      if (lot<minlot){
         lot=minlot;//min descompension lot
      }   
      
      dopartialclose(type,lot,sym);
   }
}
ulong bestpositionprofit(ENUM_POSITION_TYPE type,string sym){
   ulong ticket;
   double bestprofit=-9999999999999;
   for (int x=PositionsTotal()-1;x>=0;x--){
         if (pinfo.SelectByIndex(x) && pinfo.PositionType()==type && pinfo.Symbol()==sym){
            if (pinfo.Profit()>bestprofit){
               bestprofit=pinfo.Profit();
               ticket=pinfo.Ticket();
            }         
         }
   }
   return ticket; //return ticket with best profit order mejor seria decir mejor precio de compra

}
void dopartialclose(ENUM_POSITION_TYPE type,double lot,string sym){
   double pendinglog=lot;
   
   while (pendinglog>0){
      
      pinfo.SelectByIndex(bestpositionprofit(type,sym));
      if (pinfo.Volume()>pendinglog){ //si es una orden con mucho volumen cerramos lo que queda de volumen
         printf(pendinglog+" PATIAL  "+CountVolume(type,sym));
         trade.PositionClosePartial(pinfo.Ticket(),pendinglog);
         
         pendinglog=0;
      }else{
         printf(pendinglog+" TOTAL  "+CountVolume(type,sym));
         
         pendinglog-=pinfo.Volume();
         trade.PositionClose(pinfo.Ticket());
      }
   }
   return;
  
}

void open(ENUM_POSITION_TYPE type,double lot,string sym){


   if (type==POSITION_TYPE_BUY){
      trade.Buy(getmaxlot(lot),sym);
   }else{
      trade.Sell(getmaxlot(lot),sym);
   }
}
double getmaxlot(double trylot){
   double ret=NormalizeDouble(MathMin(trylot,maxlot),2);
   
   if(ret<minlot){
      ret=minlot;
   }
   return ret;   
}
double getProfits(ENUM_POSITION_TYPE type, string symb){

   double ret=0;
   for (int x=PositionsTotal()-1;x>=0;x--){
         if (pinfo.SelectByIndex(x) && pinfo.PositionType()==type && pinfo.Symbol()==symb)
         {
            ret+=pinfo.Profit();
         }
   }
   
   return dummyStartP+ret;
}

double getVolums(ENUM_POSITION_TYPE type, string symb){

   double ret=0;
   for (int x=PositionsTotal()-1;x>=0;x--){
         if (pinfo.SelectByIndex(x) && pinfo.PositionType()==type && pinfo.Symbol()==symb)
         {
            ret+=pinfo.Volume();
         }
   }
   
   return dummyStartV+ret;
}

double getScore(){

   double  param = 0.0;

//  Balance max + min Drawdown + Trades Number:
  double  balance = TesterStatistics(STAT_PROFIT);
  double  min_dd = TesterStatistics(STAT_BALANCE_DD);
  if(min_dd > 0.0)
  {
    min_dd = 1.0 / min_dd;
  }
  double  trades_number = TesterStatistics(STAT_TRADES);
  param = balance * min_dd * trades_number;

  return(param);

}
double getScore2(){
   double  avg_win; 
   if (TesterStatistics(STAT_PROFIT_TRADES)==0){
      avg_win= 0;
   }else{
      avg_win= TesterStatistics(STAT_GROSS_PROFIT) / TesterStatistics(STAT_PROFIT_TRADES);
   }
   
  double  avg_loss;
   if (TesterStatistics(STAT_LOSS_TRADES)==0){
      avg_loss=0;
   }else{
      avg_loss= -TesterStatistics(STAT_GROSS_LOSS) / TesterStatistics(STAT_LOSS_TRADES);
   }
   
  double  win_perc;
  
  if (TesterStatistics(STAT_TRADES)==0){
      win_perc=0;
  }else{
      win_perc= 100.0 * TesterStatistics(STAT_PROFIT_TRADES) / TesterStatistics(STAT_TRADES);
  }
  

//  Calculated safe ratio for this percentage of profitable deals:
  double  teor = (110.0 - win_perc) / (win_perc - 10.0) + 1.0;

//  Calculate real ratio:
   double  real;
  if(avg_loss==0){
   real=0;
  }else{
   real = avg_win / avg_loss;
  }
  

//  CSTS:
  double  tssf = real / teor;
   if (tssf==0){tssf=-0.1;};
  return(tssf);
}  
void docloseall(){
   for (int x=PositionsTotal()-1;x>=0;x--){
      if (pinfo.SelectByIndex(x)){
         trade.PositionClose(pinfo.Ticket());
      }   
   }
}
void getvalue(int handle,int bufnumber,int idx,int cta,double &buf[]){
   while(CopyBuffer(handle,bufnumber,idx,cta,buf)==-1){
      Sleep(100);
   }
   //CopyBuffer(handle,bufnumber,idx,cta,buf);
}
void closealloldposition(){
 for (int x=PositionsTotal()-1;x>=0;x--){
         if (pinfo.SelectByIndex(x)){
            //pinfo.
            double start_time=(double)pinfo.Time();
            double now_time=(double)TimeCurrent();
            
            if (now_time>start_time+(60*60*25*(backbars/2))){//60 seconds minut
               //more 90 minuts close
               trade.PositionClose(pinfo.Ticket());
            }
            
            
         }
               
   }
  
}
void closetypesym(ENUM_POSITION_TYPE type,string symbol){

   for (int x=PositionsTotal()-1;x>=0;x--){
      if (pinfo.SelectByIndex(x) && pinfo.PositionType()==type && pinfo.Symbol()==symbol){
         trade.PositionClose(pinfo.Ticket());
      }   
   }
}
int CountPosition(ENUM_POSITION_TYPE type,string symbol){
 int ret=0;
 for (int x=0;x<PositionsTotal();x++){
   if (pinfo.SelectByIndex(x) && pinfo.PositionType()==type && pinfo.Symbol()==symbol){
      ret++;
   } 
 }
 //ret=0;
 return ret; 

}

double CountVolume(ENUM_POSITION_TYPE type,string symbol){
 double ret=0;
 for (int x=0;x<PositionsTotal();x++){
   if (pinfo.SelectByIndex(x) && pinfo.PositionType()==type && pinfo.Symbol()==symbol){
      ret+=pinfo.Volume();
   } 
 }
 //ret=0;
 return ret; 

}
bool isValidSymbol(int x,int y){

   //csymbol.Name(moneda(x)+moneda(y));
   
   
   //return csymbol.Select();
   bool retorno = true;
   
   string val1;
   string val2;           
   val1 = moneda(x);
   val2=moneda(y);            
   
   MqlRates rates[];
   int cp=CopyRates(val1+val2,_Period,0,1,rates);
   if (cp==-1){
      retorno=false;
   }
   return retorno;
}


string moneda(int index){
 
 
 
   switch(index)
     {
      case 0: return "USD";
      case 1: return "EUR";
      case 2: return "GBP";
      case 3: return "CHF";
      case 4: return "JPY";
      case 5: return "AUD";
      case 6: return "CAD";
      case 7: return "NZD";
      
      }
      return "";
  }  
