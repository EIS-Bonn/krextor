package info.kwarc.krextor;

import java.io.IOException;
import java.net.URL;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerFactory;
import javax.xml.xpath.XPathConstants;

import net.sf.saxon.CollectionURIResolver;
import net.sf.saxon.Configuration;
import net.sf.saxon.FeatureKeys;
import net.sf.saxon.om.SequenceIterator;
import net.sf.saxon.trans.XPathException;
import nu.xom.Attribute;
import nu.xom.Builder;
import nu.xom.Document;
import nu.xom.Element;
import nu.xom.Node;
import nu.xom.Nodes;
import nu.xom.ParsingException;
import nu.xom.Text;
import nu.xom.ValidityException;
import nu.xom.XPathContext;
import nu.xom.xslt.XSLException;
import nu.xom.xslt.XSLTransform;

public class Krextor {
	private final static TransformerFactory factory;
	private final static XPathContext xPathContext;
	private final static String XMLNS_XSLT = "http://www.w3.org/1999/XSL/Transform";
	private final static String XMLNS_RXR = "http://ilrt.org/discovery/2004/03/rxr/";
	public static final String XMLNS_XML = "http://www.w3.org/XML/1998/namespace";
	
	static {
		// use Saxon as XSLT transformer
		System.setProperty("java.xml.transform.TransformerFactory",
		"net.sf.saxon.TransformerFactoryImpl");
		System.setProperty("javax.xml.transform.TransformerFactory",
				"net.sf.saxon.TransformerFactoryImpl");
		// and as XPath processor
		System.setProperty("javax.xml.xpath.XPathFactory", "net.sf.saxon.xpath.XPathFactoryImpl");
		System.setProperty("javax.xml.xpath.XPathFactory:" + XPathConstants.DOM_OBJECT_MODEL, "net.sf.saxon.xpath.XPathFactoryImpl");

		factory = TransformerFactory.newInstance();
		Configuration saxonConfiguration = new Configuration();
		saxonConfiguration.setCollectionURIResolver(new CollectionURIResolver() {
			@Override
			public SequenceIterator resolve(String href, String base,
					net.sf.saxon.expr.XPathContext context) throws XPathException {
				// TODO Auto-generated method stub
				return null;
			}
			
		});
		factory.setAttribute(FeatureKeys.CONFIGURATION, saxonConfiguration);
		
		// factory.setURIResolver(new RelativePathResolver());

		xPathContext = new XPathContext();
		xPathContext.addNamespace("rxr", XMLNS_RXR);
	}

	public Document generateStylesheet(String inputFormat, String outputFormat) throws ParserConfigurationException {
		Document result = null;
		Element root = new Element("stylesheet", XMLNS_XSLT);
		root.addAttribute(new Attribute("version", "2.0"));

		result = new Document(root); 
		result.setBaseURI(this.getClass().getResource("xslt").toString() + "/" + getTransformerName(inputFormat, outputFormat));

		Element importOutput = new Element("import", XMLNS_XSLT);
		importOutput.addAttribute(new Attribute("href", "output/" + outputFormat + ".xsl"));
		root.appendChild(importOutput);
		Element includeInput = new Element("include", XMLNS_XSLT);
		includeInput.addAttribute(new Attribute("href", "extract/" + inputFormat + ".xsl"));
		root.appendChild(includeInput);
		
		return result;
	}
	
	public String getTransformerName(String inputFormat, String outputFormat) {
		return "transform-" + inputFormat + "-" + outputFormat + ".xsl";
	}
	
	public Document getTransformer(String inputFormat, String outputFormat) {
		String tname = inputFormat + ".." + outputFormat;
		
		URL resource = this.getClass().getResource(
				getTransformerName(inputFormat, outputFormat));
		Document stylesheet = null;
		
		try {
			if (resource == null) {
				stylesheet = generateStylesheet(inputFormat, outputFormat);
			} else {
				stylesheet = new Builder().build(resource.openStream(),
						/* systemId = */ resource.toExternalForm());
			}
		} catch (IOException ex) {
			System.err.println("error while creating XSLT transformer " + tname);
			return null;
		} catch (ParserConfigurationException ex) {
			return null;
		} catch (ValidityException ex) {
			return null;
		} catch (ParsingException ex) {
			return null;
		}

		return stylesheet;
	}
	
	public Document extract(String inputFormat, String outputFormat, Document inputDocument) throws XSLException {
		XSLTransform transform = new XSLTransform(getTransformer(inputFormat, outputFormat));
		Nodes nodes = transform.transform(inputDocument);
        return XSLTransform.toDocument(nodes);
	}

	/**
	 * Extracts one component (subject, predicate or object) from an RXR triple.
	 * If there is not exactly one subject/predicate/object, a warning message is logged, and <code>null</code> returned 
	 * 
	 * @param triple the XML node representing the RDF/RXR triple
	 * @param component the desired component, as string
	 * @return the desired component as a XOM node, or <code>null</code> if there is not exactly one 
	 */
	private Element queryTripleComponent(Node triple, String component) {
		Nodes nodes = triple.query("rxr:" + component, xPathContext);
		if (nodes.size() != 1) {
			System.err.format("triple %1$s contains no %2$s or more than one %2$s", triple.toXML(), component);
			return null;
		} else {
			return (Element) nodes.get(0);
		}
	}
	
	public void extract(String inputFormat, Document inputDocument, TripleAdder callback) throws KrextorException {
		try {
			String subject = null;
			NodeType subjectType = null;
			String predicate = null;
			String object = null;
			NodeType objectType = null;
			String objectLanguage = null;
			String objectDatatype = null;
			
			// TODO figure out how to circumvent RXR and make the XSLT directly output into the callback
			Document document = extract(inputFormat, "rxr", inputDocument);
			
			System.out.println(document.toXML());
			
			Nodes triples = document.query("//rxr:triple",xPathContext);
			for (int i = 0; i < triples.size(); i++) {
				Node current = triples.get(i);

				/* determine the subject */
				Element n_subject = queryTripleComponent(current, "subject");
				if (n_subject != null) {
					if(n_subject.getAttribute("uri") != null) {
						subject = n_subject.getAttributeValue("uri");
						subjectType = NodeType.URI;
					} else if(n_subject.getAttribute("blank") != null) {
						subject = n_subject.getAttributeValue("blank");
						subjectType = NodeType.BLANK;
					} else {
						System.err.println("triple "+current.toXML()+" contains invalid subject");
					}
				}

				/* determine the predicate */
				Element n_predicate = queryTripleComponent(current, "predicate");
				if (n_predicate != null) {
					if(n_predicate.getAttribute("uri") != null) {
						predicate = n_predicate.getAttributeValue("uri");
					} else {
						System.err.println("triple "+current.toXML()+" contains invalid predicate");
					}
				}

				/* determine the object */
				Element n_object = queryTripleComponent(current, "object");
				if (n_object != null) {
					if(n_object.getAttribute("uri") != null) {
						// a URI resource
						object = n_object.getAttributeValue("uri");
						objectType = NodeType.URI;
					} else if(n_object.getAttribute("blank") != null) {
						object = n_object.getAttributeValue("blank");
						objectType = NodeType.BLANK;
					} else {
						// literal
						objectType = NodeType.LITERAL;
						
						object = "";
						for(int j = 0; j<n_object.getChildCount(); j++) {
							if(n_object.getChild(j) instanceof Text) {
								Text txt = (Text)n_object.getChild(j);
								object += txt.getValue();
							}
						}
						objectLanguage = n_object.getAttributeValue("lang", XMLNS_XML);
						objectDatatype = n_object.getAttributeValue("datatype");
					}
				}
				
				if(subject != null && predicate != null && object != null) {
					callback.addTriple(subject, subjectType, predicate, object, objectType, objectLanguage, objectDatatype);
				} else {
					// 
				}
			}

			
		} catch (XSLException ex) {
			ex.printStackTrace(System.err);
			throw new KrextorException();
		}
	}
}
