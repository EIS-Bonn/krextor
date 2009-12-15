/*  Copyright (C) 2008
 *  Christoph Lange
 *  KWARC, Jacobs University Bremen
 *  http://kwarc.info/projects/krextor/
 *
 *   Krextor is free software; you can redistribute it and/or
 *   modify it under the terms of the GNU Lesser General Public
 *   License as published by the Free Software Foundation; either
 *   version 2 of the License, or (at your option) any later version.
 *   
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *   Lesser General Public License for more details.
 *   
 *   You should have received a copy of the GNU Lesser General Public
 *   License along with this library; if not, write to the
 *   Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 *   Boston, MA 02111-1307, USA.
 */
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
// import nu.xom.XPathContext;
import nu.xom.xslt.XSLException;
import nu.xom.xslt.XSLTransform;

/**
 * A Java wrapper for the Krextor XML→RDF extraction library, which is
 * implemented in XSLT. Uses the Saxon XSLT processor.
 * 
 * Part of this implementation is based on the
 * <code>at.srfg.ikewiki.importer.RXRReader</code> class developed by Sebastian
 * Schaffert for <a href="http://ikewiki.salzburgresearch.at">IkeWiki</a>, which
 * has been released under GPL.
 * 
 * @author Christoph Lange
 */
public class Krextor {
	private final static TransformerFactory factory;
	// private final static XPathContext xPathContext;
	/**
	 * XSLT namespace URI
	 */
	public final static String XMLNS_XSLT = "http://www.w3.org/1999/XSL/Transform";
	/**
	 * RXR (Regular XML RDF) namespace URI
	 */
	public final static String XMLNS_RXR = "http://ilrt.org/discovery/2004/03/rxr/";
	/**
	 * XML namespace URI
	 */
	public static final String XMLNS_XML = "http://www.w3.org/XML/1998/namespace";
	/**
	 * RDF namespace URI
	 */
	public static final String XMLNS_RDF = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

	static {
		// use Saxon as XSLT transformer
		System.setProperty("java.xml.transform.TransformerFactory",
				"net.sf.saxon.TransformerFactoryImpl");
		System.setProperty("javax.xml.transform.TransformerFactory",
				"net.sf.saxon.TransformerFactoryImpl");
		// and as XPath processor
		System.setProperty("javax.xml.xpath.XPathFactory",
				"net.sf.saxon.xpath.XPathFactoryImpl");
		System.setProperty("javax.xml.xpath.XPathFactory:"
				+ XPathConstants.DOM_OBJECT_MODEL,
				"net.sf.saxon.xpath.XPathFactoryImpl");

		// trying how to implement catalog URI resolution, which would be nice
		// to have for FXSL
		// TODO get this right: https://trac.kwarc.info/krextor/ticket/13
		factory = TransformerFactory.newInstance();
		Configuration saxonConfiguration = new Configuration();
		saxonConfiguration
				.setCollectionURIResolver(new CollectionURIResolver() {
					@Override
					public SequenceIterator resolve(String href, String base,
							net.sf.saxon.expr.XPathContext context)
							throws XPathException {
						return null;
					}

				});
		factory.setAttribute(FeatureKeys.CONFIGURATION, saxonConfiguration);

		/*
	        xPathContext = new XPathContext();
		xPathContext.addNamespace("rxr", XMLNS_RXR);
		*/
	}

	/**
	 * Generates a Krextor XSLT stylesheet for extracting RDF from a certain
	 * input format and returning the extracted RDF in a certain output format
	 * (i.e. a RDF notation). The stylesheet is generated on the fly.
	 * 
	 * @param inputFormat
	 *            the name of the input format, as it is known to Krextor (an
	 *            XSLT file in the extract/ directory)
	 * @param outputFormat
	 *            the name of the output format, as it is known to Krextor (an
	 *            XSLT file in the output/ directory)
	 * @return a XOM representation of an XSLT stylesheet that bundles together
	 *         the desired extraction and output modules of Krextor
	 * @throws ParserConfigurationException
	 */
	public Document generateStylesheet(String inputFormat, String outputFormat)
			throws ParserConfigurationException {
		Document result = null;
		Element root = new Element("stylesheet", XMLNS_XSLT);
		root.addAttribute(new Attribute("version", "2.0"));

		result = new Document(root);
		result.setBaseURI(this.getClass().getResource(getTransformerName(inputFormat, outputFormat)).toString());

		Element importOutput = new Element("import", XMLNS_XSLT);
		importOutput.addAttribute(new Attribute("href", "output/"
				+ outputFormat + ".xsl"));
		root.appendChild(importOutput);
		Element includeInput = new Element("include", XMLNS_XSLT);
		includeInput.addAttribute(new Attribute("href", "extract/"
				+ inputFormat + ".xsl"));
		root.appendChild(includeInput);

		return result;
	}

	/**
	 * returns a filename suitable for an XSLT that transforms from an input
	 * format (XML) to an output format (RDF notation)
	 * 
	 * @param inputFormat
	 *            the name of the input format
	 * @param outputFormat
	 *            the name of the output format
	 * @return the filename
	 */
	public static String getTransformerName(String inputFormat, String outputFormat) {
		return "xslt/transform-" + inputFormat + ".." + outputFormat + ".xsl";
	}

	/**
	 * Generates a Krextor XSLT stylesheet for extracting RDF from a certain
	 * input format and returning the extracted RDF in a certain output format
	 * (i.e. a RDF notation)
	 * 
	 * @param inputFormat
	 *            the name of the input format, as it is known to Krextor (an
	 *            XSLT file in the extract/ directory)
	 * @param outputFormat
	 *            the name of the output format, as it is known to Krextor (an
	 *            XSLT file in the output/ directory)
	 * @return a XOM representation of an XSLT stylesheet that bundles together
	 *         the desired extraction and output modules of Krextor – a
	 *         ready-to-use stylesheet as bundled with Krextor, or one that is
	 *         generated on the fly using
	 *         {@link #generateStylesheet(String, String)}
	 */
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
				/* systemId = */resource.toExternalForm());
			}
		} catch (IOException ex) {
			System.err
					.println("error while creating XSLT transformer " + tname);
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

	/**
	 * Extracts RDF from an input document (XML) into an output document in an
	 * XML-based RDF notation supported by Krextor (e.g. RXR or RDF/XML)
	 * 
	 * @param inputFormat
	 *            the name of the input format, as it is known to Krextor (an
	 *            XSLT file in the extract/ directory)
	 * @param outputFormat
	 *            the name of the output format, as it is known to Krextor (an
	 *            XSLT file in the output/ directory)
	 * @param inputDocument
	 *            the input XML document
	 * @return the output, as a XOM XML document
	 * @throws XSLException
	 */
	public Document extract(String inputFormat, String outputFormat,
			Document inputDocument) throws XSLException {
		XSLTransform transform = new XSLTransform(getTransformer(inputFormat,
				outputFormat));
		Nodes nodes = transform.transform(inputDocument);
		return XSLTransform.toDocument(nodes);
	}

	/**
	 * Extracts one component (subject, predicate or object) from an RXR triple.
	 * If there is not exactly one subject/predicate/object, a warning message
	 * is logged, and <code>null</code> returned
	 * 
	 * @param triple
	 *            the XML node representing the RDF/RXR triple
	 * @param component
	 *            the desired component, as string
	 * @return the desired component as a XOM node, or <code>null</code> if
	 *         there is not exactly one
	 */
	/*
	private Element queryTripleComponent(Node triple, String component) {
		Nodes nodes = triple.query("rxr:" + component, xPathContext);
		if (nodes.size() != 1) {
			System.err.format(
					"triple %1$s contains no %2$s or more than one %2$s",
					triple.toXML(), component);
			return null;
		} else {
			return (Element) nodes.get(0);
		}
	}
	*/

	/**
	 * Extract RDF from an input XML document in a given input format and notify a callback for every RDF triple extracted
	 * 
	 * @param inputFormat
	 *            the name of the input format, as it is known to Krextor (an
	 *            XSLT file in the extract/ directory)
	 * @param inputDocument
	 *            the input XML document
	 * @param callback a callback object that is notified for every RDF triple extacted 
	 * @throws KrextorException
	 */
	public void extract(String inputFormat, Document inputDocument,
			TripleAdder callback) throws KrextorException {
		try {

			XSLTransform transform = new XSLTransform(getTransformer(inputFormat, "java"));
			transform.setParameter("triple-adder", callback);
			/* Nodes nodes = */ transform.transform(inputDocument);
			
			/* old code: extract to RXR and then parse RXR 
			String subject = null;
			String subjectType = null;
			String predicate = null;
			String object = null;
			String objectType = null;
			String objectLanguage = null;
			String objectDatatype = null;

			Document document = extract(inputFormat, "rxr", inputDocument);

			Nodes triples = document.query("//rxr:triple", xPathContext);
			for (int i = 0; i < triples.size(); i++) {
				Node current = triples.get(i);

			 	// determine the subject
				Element n_subject = queryTripleComponent(current, "subject");
				if (n_subject != null) {
					if (n_subject.getAttribute("uri") != null) {
						subject = n_subject.getAttributeValue("uri");
						subjectType = NodeType.URI;
					} else if (n_subject.getAttribute("blank") != null) {
						subject = n_subject.getAttributeValue("blank");
						subjectType = NodeType.BLANK;
					} else {
						System.err.println("triple " + current.toXML()
								+ " contains invalid subject");
					}
				}

				// determine the predicate
				Element n_predicate = queryTripleComponent(current, "predicate");
				if (n_predicate != null) {
					if (n_predicate.getAttribute("uri") != null) {
						predicate = n_predicate.getAttributeValue("uri");
					} else {
						System.err.println("triple " + current.toXML()
								+ " contains invalid predicate");
					}
				}

				// determine the object
				Element n_object = queryTripleComponent(current, "object");
				if (n_object != null) {
					if (n_object.getAttribute("uri") != null) {
						// a URI resource
						object = n_object.getAttributeValue("uri");
						objectType = NodeType.URI;
					} else if (n_object.getAttribute("blank") != null) {
						object = n_object.getAttributeValue("blank");
						objectType = NodeType.BLANK;
					} else {
						// literal
						objectType = NodeType.LITERAL;

						objectLanguage = n_object.getAttributeValue("lang",
								XMLNS_XML);
						objectDatatype = n_object.getAttributeValue("datatype");

						boolean xmlLiteral = (XMLNS_RDF + "XMLLiteral").equals(objectDatatype);

						object = "";
						for (int j = 0; j < n_object.getChildCount(); j++) {
							String serial= "";
							Node child = n_object.getChild(j);
							if (xmlLiteral) {
								serial = child.toXML();
							} else if (child instanceof Text) {
								Text txt = (Text) child;
								serial = txt.getValue();
							}
							object += serial;
						}
					}
				}

				if (subject != null && predicate != null && object != null) {
					callback.addTriple(subject, subjectType, predicate, object,
							objectType, objectLanguage, objectDatatype);
				} else {
					// 
				}
			}
			*/
		} catch (XSLException ex) {
			throw new KrextorException("An error occurred during RDF extraction, ex");
		}
	}
}
