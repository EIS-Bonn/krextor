package info.kwarc.krextor;

/**
 * An interface that must be implemented in order to get notified about all RDF triples that Krextor extracts from an XML document 
 * 
 * @author Christoph Lange
 */
public interface TripleAdder {
	/**
	 * Called whenever Krextor has extracted an RDF triple
	 * 
	 * @param subject the subject of the triple, either a URI or a blank node ID (depends on <code>subjectType</code>)
	 * @param subjectType the RDF node type of the subject, either "uri" or "blank"
	 * @param predicate the predicate of the triple, always a URI
	 * @param object the object of the triple, either a URI or a blank node ID or a literal (depends on <code>objectType</code>)
	 * @param objectType the RDF node type of the object; any type out of "uri", "blank" or "" for literals is possible
	 * @param objectLanguage the language of the object, or <code>null</code> or the empty string (depending on the implementation) if no language is set.  <code>objectLanguage</code> and <code>objectDatatype</code> are mutually exclusive, they never have both non-<code>null</code> values.
	 * @param objectDatatype the URI of the datatype of the object (usually XML Schema), or <code>null</code> or the empty string (depending on the implementation) if no datatype is set.  Mutually exclusive with <code>objectLanguage</code>. 
	 */
	public void addTriple(String subject, String subjectType, String predicate, String object, String objectType, String objectLanguage, String objectDatatype);
}
