#property copyright "Copyright 2017, Angel Lordan."
#property link      "https://www.mql5.com"
#property version   "1.00"

//all symbols abailable to trade we try to discober complex system with all symbols together
string symb[]={"EURUSD","GBPUSD","AUDUSD","USDJPY","USDCAD"};
//we send 50 orders back history
int backbars=50;
//maxtotal orders abailable per symbol and per direction(buy/sell)
int totalorders=10;
//First input layer size
int size_out1=35;
//Second input layer size
int size_out2=35;
//third input layer size
int size_out3=35;
//output layer (1-output buy 2-output lot buy 3-output sell 4-output lot sell)*for each symbol 5*4=20
int out=30;//lot 
//total number of species in population
input int numpopulation=75;
//user for selection 2 best species
input double i_tournamentSize = 5;
//if we need add best species in new generation
input bool i_elitism = true;
//user for randome crossover 
input double i_uniformRate = 0.5;
//user for random mutation rate
input double   i_mutationRate = 0.015;




double maxglobal=-999999999;
int bitlength=0;
int numinputs=0;

#include <Arrays\ArrayObj.mqh>

//+------------------------------------------------------------------+ 
//| script program start function |
 //+------------------------------------------------------------------+ 
CAlglib           Alg;
CHighQualityRandStateShell state;


 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
class Individual :  public CObject{
   public:
      int defaultGeneLength;
      double genes[];
      bool isFitted;
      double fitness;
      void initIndividual(int idefaultGeneLength); 
      void generateIndividual();
      int size();
      double getGene(int index);
      void setGene(int index, double value);
      double getFitness();
      string ToString();
      bool ReadFitness(int file);
      int tmp;
};
bool Individual::ReadFitness(int id){
   tmp++;
   if (FileIsExist((string)(id+1)+"_result.txt",FILE_COMMON)){
      int filehnd=FileOpen((string)(id+1)+"_result.txt",FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON);   
      if (filehnd!=INVALID_HANDLE){
    
         string val=FileReadString(filehnd);
         
            printf(val+" "+id);
         /*if ((double)val>=999999999999){
            val=0;
            val=0;
         }*/
         if (val=="repeat"){
            printf("repeat"+id);
            FileClose(filehnd);
            while(FileIsExist((string)(id+1)+"_result.txt",FILE_COMMON)){
               FileClose(filehnd);
               FileDelete((string)(id+1)+"_result.txt",FILE_COMMON);
            }
            return false;
         }
         isFitted=true;
         fitness=(double)val;
         
         FileClose(filehnd);
         while(FileIsExist((string)(id+1)+"_result.txt",FILE_COMMON)){
               FileClose(filehnd);
               FileDelete((string)(id+1)+"_result.txt",FILE_COMMON);
         }
      }else{
         
      }
   }
   
   return true;
    
   
}
string Individual::ToString(){
   string ret="";
   int tmp=0;
   int top=(8*4);
   string bitval="";
   int xta=size();
   for (int x=0;x<xta;x++){      
      ret+=(string)getGene(x)+",";      
   }
   return ret;
}
double Individual::getFitness() {
        double ret=0;
        //ADEBUG read fitnesfromfile!!
         //if (fitness == 0) {
           // fitness = FitnessCalc.getFitness(this);
        //}
        
        if (fitness>=0){
         ret=fitness;
        }else{
         ret=fitness*-1;
        }
        ret=fitness;
        return ret;
    }
    
void Individual::setGene(int index, double value) {
        genes[index] = value;
        fitness = 0;
}
double Individual::getGene(int index) {
      return genes[index];
}
int Individual::size() {
      return ArraySize(genes);
}
void Individual::generateIndividual() {
      for (int i = 0; i < size(); i++) {            
//            double xtime=getdatetime();
            //MathSrand(xtime*i);
            //double rand1= MathRand()/32767.0;                                    
            Alg.HQRndRandomize(&state);
            double rand1=UniformValue(-1,1);
            //bool gene = (bool) MathRound(rand1);
            
            double gene = rand1;
            genes[i] = gene;
      }
   }
        
void Individual::initIndividual(int idefaultGeneLength){
   defaultGeneLength=idefaultGeneLength;
   fitness = 0;
   isFitted=false;
   tmp=0;
   ArrayResize(genes,defaultGeneLength);   
}

//CLASS POPULATION
class Population{
   public:
   
   Individual individuals[];
   void initPopulation(int populationSize, bool initialise);
   Individual* getIndividual(int index);
   Individual* getFittest();
   int size();
   void saveIndividual(int index, Individual &indiv);
   void removezero();
   
};
void Population::removezero(){
   for (int x=0;x<size();x++){
      Individual *ind=getIndividual(x);
      if(ind.getFitness()==0){
         individuals[x]=max;
      }
      
   }
}
void Population::saveIndividual(int index, Individual &indiv) {
        individuals[index] = indiv;
 }
int Population::size() {
        return ArraySize(individuals);        
        }

Individual* Population::getFittest() {
        Individual *fittest;        
        fittest = &individuals[0];
        /*for (int i = 0; i < size(); i++) {
         fittest = &individuals[i];
         if (fittest.getFitness()!=0.0)break;
        }
        */
        // Loop through individuals to find fittest
        for (int i = 0; i < size(); i++) {
            if (fittest.getFitness() <= getIndividual(i).getFitness() && getIndividual(i).getFitness()!=0.0) {            
                fittest = getIndividual(i);
            }
        }
        return fittest;
    }
    
Individual* Population::getIndividual(int index) {   
         Individual *ind;
         ind=&individuals[index];
        return ind;
    }
    
void Population::initPopulation(int populationSize, bool initialise) {
        //individuals = new Individual[populationSize];
        ArrayResize(individuals,populationSize);
        // Initialise population
        if (initialise) {
            // Loop and create individuals
            for (int i = 0; i < size(); i++) {
                Individual *newIndividual = new Individual();
                newIndividual.initIndividual(bitlength);
                newIndividual.generateIndividual();
                saveIndividual(i, newIndividual);
            }
        }
}

class Algorithm {
     public:
      double uniformRate ;
      double mutationRate;
      int tournamentSize ;
      bool elitism ;
      void initAlgorithm();    
      void mutate(Individual &indiv);
      Population* evolvePopulation(Population &pop);
      Individual* crossover(Individual &indiv1, Individual &indiv2);
      Individual* tournamentSelection(Population &pop);
};

void Algorithm::initAlgorithm(){
       uniformRate =i_uniformRate;
       mutationRate =i_mutationRate;
       tournamentSize = i_tournamentSize;
       elitism = i_elitism;
}

 // Crossover individuals
Individual* Algorithm::crossover(Individual &indiv1, Individual &indiv2) {
        Individual *newSol = new Individual();
        newSol.initIndividual(bitlength);        
        for (int i = 0; i < indiv1.size(); i++) {        
            Alg.HQRndRandomize(&state);
            double rand1=UniformValue(-1,1);
            
            if (rand1 <= uniformRate) {
                newSol.setGene(i, indiv1.getGene(i));
            } else {
                newSol.setGene(i, indiv2.getGene(i));
            }
        }
        return newSol;
    }
 // Mutate an individual
void Algorithm::mutate(Individual &indiv) {
        // Loop through genes
        for (int i = 0; i < indiv.size(); i++) {
            Alg.HQRndRandomize(&state);
            double rand1=UniformValue(0,1);
            
            if (rand1 <= mutationRate) {
                // Create random gene                
                Alg.HQRndRandomize(&state);
                double rand1=UniformValue(0,2);                
                double gene = indiv.getGene(i)*rand1;
                indiv.setGene(i, gene);
            }
        }
    }
        
  // Select individuals for crossover
  Individual* Algorithm::tournamentSelection(Population &pop) {
        // Create a tournament population
        Population *tournament = new Population();
        tournament.initPopulation(tournamentSize, false);
        // For each place in the tournament get a random individual
        for (int i = 0; i < tournamentSize; i++) {
             
            Alg.HQRndRandomize(&state);
            double rand1=UniformValue(0,1);;                             
            
            int randomId = (int) (rand1 * pop.size());
            
            tournament.saveIndividual(i, pop.getIndividual(randomId));
        }
        // Get the fittest
        Individual *fittest = tournament.getFittest();
        return fittest;
    }        
 // Evolve a population
 Individual max;
Population* Algorithm::evolvePopulation(Population &pop) {
        Population *newPopulation = new Population;
        newPopulation.initPopulation(pop.size(), false);
        // Keep our best individual
        if (elitism) {
            //newPopulation.saveIndividual(0, pop.getFittest());                                    
            
            //pop.removezero();
            
            if (pop.getFittest().getFitness()>maxglobal){
            
               printf("MAX FITTED:"+pop.getFittest().getFitness());
               maxglobal=pop.getFittest().getFitness();
               max=pop.getFittest();
               
               string filename;
               if (newPopulation.getIndividual(0).fitness>=0){
                  filename="UPBEST.best";
               }else{
                  filename="DOWNBEST.best";
               }
               FileDelete("UPBEST.best",FILE_COMMON);
               FileDelete("DOWNBEST.best",FILE_COMMON);
               int filehnd=FileOpen(filename,FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON);
               FileWrite(filehnd,max.ToString());
               FileClose(filehnd);      
            }
            //max.tmp=0;
            newPopulation.saveIndividual(0, max);                                    
        }
        // Crossover population
        int elitismOffset;
        if (elitism) {
            elitismOffset = 1;
        } else {
            elitismOffset = 0;
        }
        // Loop over the population size and create new individuals with
        // crossover
        for (int i = elitismOffset; i < pop.size(); i++) {
            Individual indiv1 = tournamentSelection(pop);
            Individual indiv2 = tournamentSelection(pop);
            Individual newIndiv = crossover(indiv1, indiv2);
            newPopulation.saveIndividual(i, newIndiv);
        }
        // Mutate population
        for (int i = elitismOffset; i < newPopulation.size(); i++) {
            mutate(newPopulation.getIndividual(i));
        }      
        for (int i = 0; i < newPopulation.size(); i++) {
            newPopulation.getIndividual(i).isFitted=false;
        }      
        return newPopulation;
    }

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

string IntToBinary(int i){  // With thanks, code from https://forum.mql4.com/65906#1001494
  if(i==0) return "0";
  if(i<0) return "-" + IntToBinary(-i);
  string out="";
  for(;i!=0;i/=2) out=string(i%2)+out;
  return(out);
}
bool populationfinished=false;

Population *pop;
Algorithm *algorithm;


void setpoptofiles(Population &pop){
   
   for (int x=0;x<pop.size();x++){
      //split by agent
      
      Individual *ind=pop.getIndividual(x);
      int filehnd=FileOpen((string)(x+1)+".ttt",FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON);
      FileWrite(filehnd,ind.ToString());
      FileClose(filehnd);      
      msteps++; //del 0 al 69.... esperamos al resultador del 69
   }

}
int msteps=0;
int moldstep=0;
bool isprimero=true;
bool run=false;

void OnTimer(){
   //miramos si ha finalizado la population
   //if (!run)run=true;
   if (isprimero){
      printf("primero");
      isprimero=false;         
      pop=new Population();      
      pop.initPopulation(numpopulation,true);   //7 testers por 5 especies cada uno total 35 especies por epoca
      algorithm = new Algorithm();
      algorithm.initAlgorithm();
      setpoptofiles(pop);
      //le decimos que empiezen a trabajar
      //int clearRDF=FileOpen("RDFNtrees"+_Symbol+(string)_Period+".txt",FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON);
      //le ponemos los bits al fichero para cada trabajo a realizar por cada probador
      run=false;
      return;      
   }else{
   
       bool allfitted=true;
       //printf("TEST ENDING");
       for (int x=0;x<pop.size();x++){
            Individual *ind=pop.getIndividual(x);   
            if (ind.isFitted==false || FileIsExist((string)(x+1)+"_result.txt",FILE_COMMON)){
            //if (ind.isFitted==false){
               allfitted=false;
   //            printf(x+"not trainded");
               if (ind.ReadFitness(x)){
               
               }else{
            //      printf(x+"repeat");
                  //sino leemos bien
                  //entonces lo mandamos de nuevo
                  Individual *ind=pop.getIndividual(x);
                  int filehnd=FileOpen((string)(x+1)+".ttt",FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON);
                  FileWrite(filehnd,ind.ToString());
                  FileClose(filehnd);      
               }
                              
               
            }            
       }
     
       if (allfitted){         
         //
         //printf("ALLTRADED");
         string filter="*.txt";
         string file_name;
         long search_handle=FileFindFirst(filter,file_name,FILE_COMMON);

         if(search_handle!=INVALID_HANDLE)
   
         { run=false;
            return; //si hay datos volvemos!
         }
         pop = algorithm.evolvePopulation(pop);       
         setpoptofiles(pop); //enviamos la red evolucionada!
         moldstep=msteps;
         printf("EVOLVED");
       }
   }            
//ADEBUG population       
   
run=false;
}
bool finishedallgenerations(){
   bool ret=false;      
   if(FileIsExist((string)(msteps-1)+"_result.txt",FILE_COMMON)){
      ret=true;
      Sleep(100);
   }else{
      
   }
   return ret;
   

}
int OnInit()
  {
//---
 
   
   
   numinputs=backbars*2*totalorders;   
   
   int TOTALINTNUMBERS=(numinputs*size_out1)+(size_out1*size_out2)+(size_out2*size_out3)+(size_out3*out);
   //TOTALINTNUMBERS=
   //TOTALINTNUMBERS=(numinputs*size_out1)+(size_out1*size_out2)+(size_out2*out);
   
   bitlength=TOTALINTNUMBERS;
   
   
   EventSetMillisecondTimer(1500);   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   EventKillTimer();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
  {
//---
      
   
  }
//+------------------------------------------------------------------+


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
  
  double UniformValue(double min,double max)
  {
   Alg.HQRndRandomize(&state);//инициализация
   if(max>min)
      return Alg.HQRndUniformR(&state)*(max-min)+min;
   else
      return Alg.HQRndUniformR(&state)*(min-max)+max;
  }