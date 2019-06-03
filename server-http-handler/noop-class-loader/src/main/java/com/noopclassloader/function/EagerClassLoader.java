package com.noopclassloader.function;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Enumeration;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;

public class EagerClassLoader extends ClassLoader {

    private String jarFilePath;
    private byte[] buffer;
    private final int bufferSize = 10000;

    public EagerClassLoader(String jarFilePath) {
        this.jarFilePath = jarFilePath;
        this.buffer = new byte[this.bufferSize];
    }

    public void loadJarClasses() throws IOException {
        long readingTime = 0;
        long interpretingTime = 0;
        try (JarFile jarFile = new JarFile(this.jarFilePath)) {
            Enumeration<JarEntry> enumOfJar = jarFile.entries();
            while (enumOfJar.hasMoreElements()) {
                JarEntry entry = enumOfJar.nextElement();
                if (!entry.isDirectory() && entry.getName().endsWith(".class")) {
                    System.out.println(entry.getName());
                    //String className = "/" + fullClassName.replaceAll("\\.", "/") + ".class";
                    try (InputStream is = jarFile.getInputStream(entry)) {
                        long startReader = System.nanoTime();
                        byte[] byteArr = toByteArray(is);
                        long startInterpreter = System.nanoTime();
                        defineClass(entry.getName(), byteArr, 0, byteArr.length);
                        readingTime += startInterpreter - startReader;
                        interpretingTime += System.nanoTime() - startInterpreter;
                    }
                }
            }
        }
        System.out.println("RT: " + readingTime);
        System.out.println("IT: " + interpretingTime);
    }

    private byte[] toByteArray(InputStream inputStream) throws IOException {
        ByteArrayOutputStream out = new ByteArrayOutputStream(this.bufferSize);
        int read;
        while ((read = inputStream.read(this.buffer, 0, this.buffer.length)) != -1) {
            out.write(this.buffer, 0, read);
        }
        out.flush();
        return out.toByteArray();
    }

}
