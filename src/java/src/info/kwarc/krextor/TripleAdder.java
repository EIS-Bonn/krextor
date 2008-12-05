package info.kwarc.krextor;

public interface TripleAdder {
	public void addTriple(String subject, NodeType subjectType, String predicate, String object, NodeType objectType, String objectLanguage, String objectDatatype);
}
