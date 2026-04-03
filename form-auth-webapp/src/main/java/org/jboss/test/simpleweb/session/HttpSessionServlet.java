package org.jboss.test.simpleweb.session;

import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet(name = "HttpSessionServlet", urlPatterns = {"/session", "/session/*"})
public class HttpSessionServlet extends HttpServlet {

    private static final Logger log = Logger.getLogger(HttpSessionServlet.class.getName());
    private static final String KEY = HttpSessionServlet.class.getName();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        HttpSession session = req.getSession(true);

        if (session.isNew()) {
            log.log(Level.INFO, "New session created: {0}", session.getId());
            session.setAttribute(KEY, new SerialBean());
        } else if (session.getAttribute(KEY) == null) {
            log.log(Level.INFO, "Session is not new, creating SerialBean: {0}", session.getId());
            session.setAttribute(KEY, new SerialBean());
        }

        SerialBean bean = (SerialBean) session.getAttribute(KEY);

        resp.setContentType("text/plain");

        int serial = bean.getSerial();
        bean.setSerial(serial + 1);

        session.setAttribute(KEY, bean);

        resp.getWriter().print(serial);
    }

    @Override
    public String getServletInfo() {
        return "Servlet using Session to store object with the serial.";
    }
}
