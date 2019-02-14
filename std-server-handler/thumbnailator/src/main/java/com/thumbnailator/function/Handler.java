package com.thumbnailator.function;

import java.lang.management.GarbageCollectorMXBean;
import java.lang.management.ManagementFactory;
import java.util.List;
import java.lang.Error;
import net.coobird.thumbnailator.Thumbnails;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;

import javax.imageio.ImageIO;

public class Handler {

    public static void main(String[] args) throws IOException {
    	while (true) {
    		System.err.println("T5: " + System.currentTimeMillis());
    		
    		getCharFromStdin();
    		
            List<GarbageCollectorMXBean> gcs = ManagementFactory.getGarbageCollectorMXBeans();
            GarbageCollectorMXBean scavenge = gcs.get(0);
            GarbageCollectorMXBean markSweep = gcs.get(1);

            long countBeforeScavenge = scavenge.getCollectionCount();
            long timeBeforeScavenge = scavenge.getCollectionTime();
            long countBeforeMarkSweep = markSweep.getCollectionCount();
            long timeBeforeMarkSweep = markSweep.getCollectionTime();
            long before = System.currentTimeMillis();

            String err = callFunction();

            long after = System.currentTimeMillis();
            long countAfterScavenge = scavenge.getCollectionCount();
            long timeAfterScavenge = scavenge.getCollectionTime();
            long countAfterMarkSweep = markSweep.getCollectionCount();
            long timeAfterMarkSweep = markSweep.getCollectionTime();

            String processName = java.lang.management.ManagementFactory.getRuntimeMXBean().getName();
            long pid = Long.parseLong(processName.split("@")[0]);

            String output = err + System.lineSeparator();
            if (err.length() == 0) {
                output = Long.toString(pid) + "," + // Pid
                        Long.toString(after - before) + "," + // Business Logic Time in Milliseconds
                        Long.toString(countAfterScavenge - countBeforeScavenge) + "," + // Scavenge
                                                                                        // Number of
                                                                                        // Collections
                        Long.toString(timeAfterScavenge - timeBeforeScavenge) + "," + // Scavenge
                                                                                      // Collections
                                                                                      // Time Spent in
                                                                                      // Milliseconds
                        Long.toString(countAfterMarkSweep - countBeforeMarkSweep) + "," + // MarkSweep
                                                                                          // Number of
                                                                                          // Collections
                        Long.toString(timeAfterMarkSweep - timeBeforeMarkSweep); // MarkSweep
                                                                                 // Collections Time
                                                                                 // Spent in
                                                                                 // Milliseconds
            }

            System.out.println(output);
            System.err.println("T6: " + System.currentTimeMillis());
    	}
    }
    
    private static char getCharFromStdin() throws IOException {
    	return (char) System.in.read();
    }

    static double scale;
    static BufferedImage image;
    static {
        try {
            scale = Double.parseDouble(System.getenv("scale"));
            image = ImageIO.read(new File(System.getenv("image_path")));
        } catch (Exception e) {
            System.err.println(e.getMessage());
        }
    }

    public static String callFunction() {
        String err = "";
        try {
            Thumbnails.of(image).scale(scale).asBufferedImage();

        } catch (Exception e) {
            err = e.toString() + System.lineSeparator() + e.getCause() + System.lineSeparator()
                    + e.getMessage();
            e.printStackTrace();

        } catch (Error e) {
            err = e.toString() + System.lineSeparator() + e.getCause() + System.lineSeparator()
                    + e.getMessage();
            e.printStackTrace();
        }

        return err;
    }

}
