/* Copyright 2015 Pablo Cremades
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
/**************************************************************************************
* Autor: Pablo Cremades
* Fecha: 03/08/2016
* e-mail: pablocremades@gmail.com
* Descripción: Aplicación para medir velocidad de los sensores INGKA. Para iniciar
* una medición, conecte el equipo de adquisición de datos a la PC y presione el
* botón "Iniciar". Cuando termine, presione el botón "Detener".
*
* Change Log:
* - Borrar el código para inicializar la placa con comandos de teclado!!!!
* 04/08/2016: Agregué slider para el definir el ancho de la bandera.
* - 11/08/2016: Esta versión funciona por interrupciones. Hay Sensores
*  de INGKA que por alguna razón no funcionan!!!!!!!!!!
*/

import g4p_controls.*;
import processing.serial.*;

String[] serialPorts;
Serial port;
GButton Iniciar, Detener;
GSlider BanderaSld;
float BanderaWidth;
String inString = "";
String[] list;
float[] tiempo = new float[2];
int[] sensorStatus = {0, 0};
float[] sensorSpeed = new float[2];

void setup(){
  size(400, 300);
  serialPorts = Serial.list(); //Get the list of tty interfaces
  for( int i=0; i<serialPorts.length; i++){ //Search for ttyACM*
    if( serialPorts[i].contains("ttyACM") ){  //If found, try to open port.
                println(serialPorts[i]);
      try{
        port = new Serial(this, serialPorts[i], 115200);
        port.bufferUntil(10);
      }
      catch(Exception e){
      }
    }
  }
  
  //Create the buttons.
  Iniciar = new GButton(this, 20, 20, 100, 30, "Iniciar");
  Detener = new GButton(this, 150, 20, 100, 30, "Detener");
  BanderaSld = new GSlider(this, 140, 250, 100, 15, 10);
  BanderaSld.setLimits(1.0, 15.0);
  BanderaSld.setValue(1);
}

void draw(){
  background(255);
  fill(0);
  if( port == null ){  //If failed to open port, print errMsg and exit.
    println("Equipo desconectado. Conéctelo e intente de nuevo.");
    exit();
  }
  
  //Draw the texts.
  text( "Sensor 1", 20, 100);
  text( str(sensorSpeed[0]), 20,150);
  text( "[m/s]", 70, 150);
  text( "Sensor 2", 150, 100);
  text( str(sensorSpeed[1]), 150,150);
  text( "[m/s]", 200, 150);
  text( "Largo de Bandera:", 20, 260);
  text( str(BanderaWidth), 250, 260);
  text( "[cm]", 280, 260);
 
 //---------------->Remove this code.
 if( keyPressed ){
  //Cerrar comunicación y desconectar sensores.
  if( key == 'c' ){
    port.write("#0021");
    exit();
  }
  //Inicio de la comunicación.
  else if( key == 's' ){
    port.write("#0001");  //Inicio.
    delay(100);
    port.write("#0031 462815232 1943863296 831782912 1421148160 ");  //Código de autenticación
    delay(100);
    port.write("#0033 239589820 3486795892 3188765557 2136465651 ");  //Código de autenticación
  }
  //Listar estado de los puertos (sensores).
  else if( key == 'l' ){
    port.write("#0003");
    delay(100);
  }
  //Conectar fotogate
  else if( key == 'g' ){
    port.write("#0007");
    delay(100);
    port.write("#0005,2,2,2,3,10,1,0,1,1,1,1,1,1,1");  //Sensor 0
    delay(100);
    port.write("#0005,3,2,2,3,15,1,0,1,1,1,1,1,1,1");  //Sensor 1
    delay(100);
  }
 }
 
 //If there is a string available on the port, parse it.
 //Strings not begining with # are data from SAD.
 if(inString.length() > 5 && inString.charAt(0) != '#'){
   print(inString);
   list = split(inString, "\t"); //Split the string.
   int sensor = Integer.parseInt(list[0]) - 2; //Los sensores digitales son 2 y 3. Restamos 2 para usar de index (0 y 1).
   if( sensor == 0 || sensor == 1 ){
     int status = Integer.parseInt(list[2].trim());  //Status is in the 3rd substring
     if( status != sensorStatus[sensor] ){  //If status for any sensor changed from last time...
       if(status == 1) //status=1 means sensor is blocked. Start counting time.
         tiempo[sensor] =  Float.parseFloat(list[1]);
       else{  //Sensor is no longer blocked. Determine the time that has passed.
         tiempo[sensor] =  Float.parseFloat(list[1]) - tiempo[sensor];
         //print(sensor); print(" "); println(tiempo[sensor]);
         //Round to 3 signigicant digits.
         sensorSpeed[sensor] = round(BanderaWidth/100/tiempo[sensor]*100000000)/100.0;
       }
       sensorStatus[sensor] = status; //Update sensor status.
     }
   }
   inString = ""; //Empty the string.
 }
}

//Read the incoming data from the port.
void serialEvent(Serial port) { 
  inString = port.readString();
}

//Buttons event handler.
void handleButtonEvents(GButton button, GEvent event) {
   if(button == Iniciar && event == GEvent.CLICKED){
      port.write("#0001");  //Inicio.
      delay(100);
      port.write("#0031 462815232 1943863296 831782912 1421148160 ");  //Código de autenticación
      delay(100);
      port.write("#0033 239589820 3486795892 3188765557 2136465651 ");  //Código de autenticación
      delay(100);
      port.write("#0007");
      delay(100);
      port.write("#0005,2,3,2,3,10,1,0,1,1,1,1,1,1,1");  //Sensor 0
      delay(100);
      port.write("#0005,3,3,2,3,15,1,0,1,1,1,1,1,1,1");  //Sensor 1
      delay(100);
   }
   else if(button == Detener && event == GEvent.CLICKED){
      port.write("#0021"); //Close comunication.
      exit(); //Exit the app.
   }
}

void handleSliderEvents(GValueControl slider, GEvent event){
 BanderaWidth = BanderaSld.getValueF();
 BanderaWidth = float(round(BanderaWidth*10))/10.0;
}