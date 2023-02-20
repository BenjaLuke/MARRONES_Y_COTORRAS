/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package cut7;

import static CUT7.CUT7.ultimoValor;
import java.awt.image.BufferedImage;
import java.awt.image.DataBufferByte;
import java.io.File;
import java.io.FileOutputStream;
import java.util.StringTokenizer;
import javax.imageio.ImageIO;

/**
 *
 * @author Benjami
 */
public class CUT7 {

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
        // TODO code application logic here
         /**
     * @param args the command line arguments
     */
    public static void main(String[] args) throws Exception {
        // TODO code application logic here
         //Lectura de parametros
        if (args.length!=1) {
            System.out.println("CUT7  <archivo>");
            System.out.println("");
            System.out.println("Deja el archivo tal cual pero con los 7 primeros bytes cortados");
            System.out.println("esto va bien para quitar las cabeceras de BIN en archivos MSX.");
            System.out.println("Developed by Benjamín (CARAMBALÁN Studios");
            System.exit(1);
        }
        
               ////arg[0] es un String que contiene el nombre del fichero de origen
               
     //Lectura del fichero de origen
        BufferedImage img = ImageIO.read(new File(args[0]));
                
        int restar == 7
                
        
        
        byte[] bloqueDestino = new byte[(ultimoValor(tamaño,bytesPorBloque)];
        int bloqueDestinoIndex = 0;
        
        for (int a=0; a<(tamaño+1);a=a+(bytesPorBloque)) {
        for (byte i=0; i<(ultimoValor+1); i++ ) {
            //System.out.println(img.getColorModel().getRed(i)  + " " +
            //img.getColorModel().getGreen(i)  + " " +
            //img.getColorModel().getBlue(i)
            bloqueDestino[bloqueDestinoIndex++] = (byte)"aquí paso byte a byte hasta la cantidad que tiene ultimoValor";
        }
        
        FileOutputStream fos = new FileOutputStream(filename+ultimoValor(tamaño,bytesPorBloque)+ultimoValor".DAT");
        fos.write(bloqueDestino);
        fos.close();           
    }
    
}
