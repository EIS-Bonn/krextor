package info.kwarc.krextor;

/**
 * A type of an RDF node
 * 
 * @author Christoph Lange
 *
 */
public enum NodeType {
	/**
	 * a URI 
	 */
	URI,
	/**
	 * a bnode (blank node)
	 */
	BLANK,
	/**
	 * a literal
	 */
	LITERAL
}
