package com.noopclassloader.function;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;

public class EagerClassLoader extends ClassLoader {

    private JarFile jarFile;
    private byte[] buffer;
    private final int bufferSize = 10000;
    private long readingTime = 0;
    private long interpretingTime = 0;
    private long totalLoaded = 0;
    private Map<String, Class<?>> mapClass;

    public EagerClassLoader(String jarFilePath) throws IOException {
        this.jarFile = new JarFile(jarFilePath);
        this.buffer = new byte[this.bufferSize];
        this.mapClass = new HashMap<String, Class<?>>();
    }

    public void loadJarClasses() throws IOException, ClassNotFoundException {
        try {
            Enumeration<JarEntry> enumOfJar = jarFile.entries();
            while (enumOfJar.hasMoreElements()) {
                JarEntry entry = enumOfJar.nextElement();
                if (!entry.isDirectory() && entry.getName().endsWith(".class")) {
                    String className =
                            entry.getName().replaceAll("/", ".").replaceAll(".class", "");
                    loadClass(className);
                }
            }
            System.out.println("RT: " + this.readingTime);
            System.out.println("IT: " + this.interpretingTime);
            System.out.println("TL: " + this.totalLoaded);
        } finally {
            this.jarFile.close();
        }
    }


    @Override
    protected synchronized Class<?> loadClass(String name, boolean resolve)
            throws ClassNotFoundException {
        System.out.println(name);
        Class<?> c = this.mapClass.get(name);
        if (c != null) {
            System.out.println("ARD");
            return c;
        }
        JarEntry entry = this.jarFile.getJarEntry(name.replaceAll("\\.", "/") + ".class");
        if (entry != null) {
            System.out.println("ECLDG");
            try (InputStream is = this.jarFile.getInputStream(entry)) {
                long startReader = System.nanoTime();
                byte[] byteArr = toByteArray(is);
                long startInterpreter = System.nanoTime();
                c = defineClass(name, byteArr, 0, byteArr.length);
                try {
                    c.newInstance();
                } catch (Throwable e) {
                }
                this.interpretingTime += System.nanoTime() - startInterpreter;
                this.readingTime += startInterpreter - startReader;
                this.totalLoaded += byteArr.length;
                this.mapClass.put(name, c);
                return c;
            } catch (IOException e) {
                e.printStackTrace();
                throw new ClassNotFoundException(name);
            } finally {
                if (c != null && resolve) {
                    resolveClass(c);
                }
            }
        } else {
            System.out.println("DCLDG");
            try {
                long startInterpreter = System.nanoTime();
                c = getClass().getClassLoader().loadClass(name);
                this.interpretingTime += System.nanoTime() - startInterpreter;
            } catch (Throwable e) {
                e.printStackTrace();
            }
            return c;
        }
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
