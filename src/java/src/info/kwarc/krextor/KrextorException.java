package info.kwarc.krextor;

/**
 * Any exception that can occur in the case of initializing or running Krextor
 * 
 * @author Christoph Lange
 */
public class KrextorException extends Exception {
	public KrextorException(String msg) {
		super(msg);
	}

	public KrextorException(String msg, Throwable cause) {
		super(msg, cause);
	}
}
