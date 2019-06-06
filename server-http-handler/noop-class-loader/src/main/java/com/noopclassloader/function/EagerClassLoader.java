package com.noopclassloader.function;

import java.io.IOException;
import java.util.Enumeration;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;

public class EagerClassLoader extends ClassLoader {

    private JarFile jarFile;
    private long rt = 0L;
    private long ct = 0L;
    private int counter = 0;

    public EagerClassLoader(String jarFilePath) throws IOException {
        this.jarFile = new JarFile(jarFilePath);
    }

    public String loadJarClasses() throws IOException {
        long startTime = System.nanoTime();
        try {
            ClassLoader cLoader = getClass().getClassLoader();
            Enumeration<JarEntry> entries = this.jarFile.entries();
            while (entries.hasMoreElements()) {
                JarEntry e = entries.nextElement();
                if (!e.isDirectory() && e.getName().startsWith("generated")
                        && e.getName().endsWith(".class")) {

                    String className = e.getName().replaceAll("\\.class", "").replaceAll("/", ".");
                    try {
                        long sr = System.nanoTime();
                        Class<?> c = cLoader.loadClass(className);
                        long si = System.nanoTime();
                        try {
                            c.getConstructor().newInstance();
                        } catch (Throwable ee) {
                            ee.printStackTrace();
                        }
                        long end = System.nanoTime();

                        this.rt += si - sr;
                        this.ct += end - si;
                        this.counter++;
                    } catch (ClassNotFoundException e1) {
                        e1.printStackTrace();
                    }
                }
            }
            return "Loading Classes Time: " + this.rt + System.lineSeparator()
                    + "Interpreting Classes Time: " + this.ct + System.lineSeparator()
                    + "Loaded Classes: " + this.counter + System.lineSeparator()
                    + "Total Load Time: " + (System.nanoTime() - startTime);
        } finally {
            this.jarFile.close();
        }
    }

}
