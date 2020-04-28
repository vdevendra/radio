// Порты для LM
#define CE (12) //LM7001 PIN3
#define CL (11) //LM7001 PIN4
#define DA (10) //LM7001 PIN5
// Задержка на тактах, в микросекундах
#define LM_DELAY (2)

void setup()      
{     
Serial.begin(9600);
pinMode(CE, OUTPUT);
pinMode(CL, OUTPUT);
pinMode(DA, OUTPUT);
// Да будет радио сразу!
//SetRF(1017);
}      

void loop()      
{   
int inRF;
byte p[2];
int t;

ReadSteering();

// Длина команды 8 байт, формат:
// rfXXXXX<cr>
t = Serial.available();
if (t >= 8)
  {
    p[0] = Serial.read();
    p[1] = Serial.read();
    if ( p[0]==114 and p[1]==102 )
    {
      inRF = 1;
      for (int x=3; x>=0; x--)
        {
          inRF += (int(Serial.read())-48) * pow(10, x);
        }
      Serial.flush();  
      if (inRF >= 875 and inRF <= 1080)  {SetRF(inRF); SendOK();}
      else {SendERR();}   
    }
    else {SendERR();}
  }
  else 
  {
  if (t > 0) {Serial.flush(); SendOK();}
  }
  delay(100);
} 

// Читает рулевые кнопки и пишет в порт код нажатой кнопки

void ReadSteering()      
{   
  byte bytes[2];  
  unsigned int res_dt1 = analogRead(0); // прочитать данные АЦП  
  delay(50); 
  unsigned int res_dt2 = analogRead(0); //проверка дребезга  
    if (abs(res_dt1-res_dt2)<=20 and res_dt1<1000 ) //если нет дребезга и что-то есть
      { 
        bytes[0] = 255;
        bytes[1] = res_dt1 & 255;          // преобразовать в 2-байта  
        bytes[2] = (res_dt1 & 768) >> 8;  
        Serial.write( bytes,3); // отправить прочитаное значение компьютеру      
      }   
/*Serial.print(res_dt1,DEC);
Serial.print("   ");
Serial.println(res_dt2,DEC);*/
} 

void SetRF(int RF)
{
  RF += 107;
  // Выставляем CE, говорим что пишем в LM
  digitalWrite(CE, HIGH);
  writeToLM(byte(RF));
  writeToLM(byte(RF >> 8));
  writeToLM(135);
  // Снимаем CE, все отправили
  digitalWrite(CE, LOW);
}

void writeToLM(byte ByteToSend)
{
int D; 
int D1;

  delayMicroseconds(LM_DELAY);
  for (int x=0; x<=7; x++)
    {
      // Выставляем DA
      D = ByteToSend >> 1;
      D1 = D << 1;
      if (ByteToSend==D1)  // Значит был 0
        {
          digitalWrite(DA,LOW);
        }
      else
        {
          digitalWrite(DA,HIGH);         
        }  
      // Формируем строб CL  
      digitalWrite(CL, HIGH);
      delayMicroseconds(LM_DELAY);
      digitalWrite(CL,LOW);
      delayMicroseconds(LM_DELAY);  
      ByteToSend = ByteToSend >> 1;    
    }
  delayMicroseconds(LM_DELAY);
}

void SendOK()
{
  Serial.println("OK");
}

void SendERR()
{
  Serial.println("ER");
} 
