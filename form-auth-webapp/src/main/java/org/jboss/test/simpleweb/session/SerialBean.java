package org.jboss.test.simpleweb.session;

import java.io.Serializable;

public class SerialBean implements Serializable {

    private static final long serialVersionUID = 1L;

    private int serial = 0;
    private final byte[] cargo;

    public SerialBean() {
        this.cargo = new byte[0];
    }

    public int getSerial() {
        return serial;
    }

    public void setSerial(int serial) {
        this.serial = serial;
    }
}
