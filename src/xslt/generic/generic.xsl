<?xml version="1.0" encoding="UTF-8"?>

<!--
    *  Copyright (C) 2008
    *  Christoph Lange
    *  KWARC, Jacobs University Bremen
    *  http://kwarc.info/projects/krextor/
    *
    *   Krextor is free software; you can redistribute it and/or
    * 	modify it under the terms of the GNU Lesser General Public
    * 	License as published by the Free Software Foundation; either
    * 	version 2 of the License, or (at your option) any later version.
    *
    * 	This program is distributed in the hope that it will be useful,
    * 	but WITHOUT ANY WARRANTY; without even the implied warranty of
    * 	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    * 	Lesser General Public License for more details.
    *
    * 	You should have received a copy of the GNU Lesser General Public
    * 	License along with this library; if not, write to the
    * 	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
    * 	Boston, MA 02111-1307, USA.
    * 
-->

<!DOCTYPE stylesheet [
    <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
]>

<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" 
    xpath-default-namespace="http://www.w3.org/1999/XSL/Transform"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    xmlns:krextor-genuri="http://kwarc.info/projects/krextor/genuri"
    xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:f="http://fxsl.sf.net/"
    exclude-result-prefixes="#all"
    version="2.0">

    <import href="util.xsl"/>

    <xd:doc type="stylesheet">
	<xd:short>Convenience functions and templates for extracting RDF from XML languages, independent both from the XML input language and from the RDF output notation</xd:short>
	<xd:detail><p>This stylesheet provides convenience functions and templates for an RDF extraction from XML languages.  It is independent of any RDF output notation.</p></xd:detail>
	<xd:author>Christoph Lange</xd:author>
	<xd:copyright>Christoph Lange, 2008</xd:copyright>
	<xd:svnId>$Id$</xd:svnId>
    </xd:doc>

    <xd:doc>Enable debug output?</xd:doc>
    <param name="debug" select="false()"/>
    <!-- Should URIs like document#fragment automatically be generated?
         This is a sequence of string values:
	 * 'xml-id': use the xml:id attribute if available, otherwise nothing
	 * 'document-root-base': use the base URI if we are on the root
	   element, otherwise nothing.  Note that for meaningful results you
	   should not pass a manipulated base URI into create-resource.
	 * 'generate-id': generate via generate-id() function (always succeeds)
	 * 'pseudo-xpath': generate an XPath-like expression from the local 
	   names and local positions of the element and its parents (always
	   succeeds; can lead to clashes if elements from different namespaces
	   with the same local names are used in the same context or if dashes
	   are used within element names; inefficient because the whole XPath
	   from the root is newly computed for every element); example:
	   doc-section2-para1 = /doc/section[2]/para[1]
	
	 The default setting is ('xml-id' 'document-root-base').  If one method
	 fails to generate a URI, the next one in the list is tried.

	 Note that there is no guarantee that generate-id and pseudo-xpath 
	 generate URIs that differ from all xml:ids in the document.  We leave
	 the responsibility of not creating xml:ids too obscure to the document
	 author.

	 Also note that any fragment ID that the base URI of the document
	 already has is discarded and replaced by the generated fragment ID, if
	 Krextor is instructed to generate one.  More than one fragment is not
	 allowed by the URI RFC 3986 (http://www.faqs.org/rfcs/rfc3986.html).
	 See
	 http://www.aifb.uni-karlsruhe.de/pipermail/swikig/2006-February/000095.html
	 for more background on this in a semantic web context.
    -->
    <param name="autogenerate-fragment-uris" select="
	'xml-id',
	'document-root-base'"/>

    <!-- Should XIncludes be traversed?  Note: Templates for nodes in XIncluded
         documents are matched in "krextor:included" mode. -->
    <param name="traverse-xincludes" select="true()"/>

    <variable name="krextor:resources" select="()"/>
    <variable name="krextor:literal-properties" select="()"/>

    <xd:doc>Checks whether a given node is a text node, an attribute, or an atomic value</xd:doc>
    <function name="krextor:is-text-or-attribute-or-atomic">
	<param name="node"/>
        <sequence select="$node instance of xs:anyAtomicType
            or $node instance of text()
            or $node instance of attribute()"/>
    </function>

    <xd:doc>Generates a URI for a fragment of a document; returns the empty sequence if the fragment ID is empty</xd:doc>
    <function name="krextor:fragment-uri-or-null">
	<param name="fragment-id"/>
	<param name="base-uri"/>
	<value-of select="if ($fragment-id)
	    then resolve-uri(concat('#', $fragment-id), $base-uri)
	    else ()"/>
    </function>

    <xd:doc>creates an XPath-like string from the path to a node, 
	e.g. <code>doc-sect1-para2</code> for <code>/doc/sect[1]/para[2]</code></xd:doc>
    <function name="krextor:pseudo-xpath">
	<param name="node"/>
	<value-of select="if ($node/parent::node() instance of document-node())
		then local-name($node)
	    else concat(
		krextor:pseudo-xpath($node/parent::node()),
		'-',
		local-name($node),
		count($node/preceding-sibling::node()) + 1
		)"/>
    </function>

    <xd:doc>Generates a URI for a resource</xd:doc>
    <function name="krextor:generate-uri">
        <param name="node"/>
        <param name="autogenerate-fragment-uri"/>
        <param name="base-uri"/>
	<!-- What we'd actually like to do is applying a series of _functions_
	to ($node, $base-uri), but that doesn't work.  It would involve
	currying, and the FXSL implementation of currying breaks nodes in XML
	documents -->
	<value-of select="f:return-first(krextor:generate-uri-impl(), $autogenerate-fragment-uri, ($node, $base-uri))"/>
    </function>

    <function name="krextor:generate-uri-impl">
	<param name="method"/>
	<param name="params"/>
	<variable name="node" select="$params[1]"/>
	<variable name="base-uri" select="$params[2]"/>
	<variable name="method-element">
	    <element name="{concat('krextor-genuri:', $method)}"/>
	</variable>
	<apply-templates select="$method-element/*">
	    <with-param name="node" select="$node"/>
	    <with-param name="base-uri" select="$base-uri"/>
	</apply-templates>
    </function>

    <template match="krextor-genuri:document-root-base" as="xs:string?">
	<param name="node"/>
	<param name="base-uri"/>
	<sequence select="
	    if ($node/parent::node() instance of document-node())
	    then $base-uri
	    else ()"/>
    </template>

    <template match="krextor-genuri:xml-id|krextor-genuri:generate-id|krextor-genuri:pseudo-xpath" as="xs:string?">
	<param name="node"/>
	<param name="base-uri"/>
	<sequence select="
	    krextor:fragment-uri-or-null(
		if (self::krextor-genuri:xml-id and $node/@xml:id)
		    then $node/@xml:id
		else if (self::krextor-genuri:generate-id)
		    then generate-id($node)
		else if (self::krextor-genuri:pseudo-xpath)
		    then krextor:pseudo-xpath($node)
		else (),
		$base-uri)"/>
    </template>

    <function name="krextor:generate-uri-impl" as="element()">
	<krextor:generate-uri-impl/>
    </function>

    <template match="krextor:generate-uri-impl" mode="f:FXSL">
	<param name="arg1"/>
	<param name="arg2"/>
	<sequence select="krextor:generate-uri-impl($arg1, $arg2)"/>
    </template>

    <xd:doc>Calls the output module template that outputs one RDF triple; URIs
	are resolved against the base URI before, if there is a base
	URI.</xd:doc>
    <template name="krextor:output-triple-impl">
	<!-- value of the subject -->
	<param name="subject" required="yes"/>
	<!-- type of the subject: either 'uri' or 'blank' -->
	<param name="subject-type" select="'uri'"/>

	<!-- value of the predicate -->
	<param name="predicate" required="yes"/>

	<!-- value of the object -->
	<param name="object" required="yes"/>
	<!-- type of the object: either 'uri' or 'blank',
	     or nothing for literal objects -->
	<param name="object-type"/>
	<!-- language annotation is only supported on the object,
	     but neither on triples nor on graphs, as in RXR -->
	<param name="language"/>
	<!-- datatype of the (literal) object -->
	<param name="datatype"/>

	<!-- We accept a static base URI (as, e.g., defined by base/@href in XHTML), against which every URL is resolved -->
	<param name="krextor:base-uri" tunnel="yes"/>

	<!-- Some sanity checks -->
	<if test="not($subject-type = ('uri', 'blank'))">
	    <message terminate="yes" select="concat('Invalid subject type: ', $subject-type)"/>
	</if>
	<if test="not($object-type = ('uri', 'blank', ''))">
	    <message terminate="yes" select="concat('Invalid object type: ', $subject-type)"/>
	</if>

	<!-- Call the output module -->
	<call-template name="krextor:output-triple">
	    <with-param name="subject" select="if ($subject-type eq 'uri' and $krextor:base-uri)
		then resolve-uri($subject, $krextor:base-uri)
		else $subject"/>
	    <with-param name="subject-type" select="$subject-type"/>
	    <with-param name="predicate" select="$predicate"/>
	    <with-param name="object" select="if ($object-type eq 'uri' and $krextor:base-uri)
		then resolve-uri($object, $krextor:base-uri)
		else $object"/>
	    <with-param name="object-type" select="$object-type"/>
	    <with-param name="object-language" select="$language"/>
	    <with-param name="object-datatype" select="$datatype"/>
	</call-template>
    </template>

    <xd:doc>Relates the current resource to its parent via some properties or their inverses</xd:doc>
    <template name="krextor:related-via-properties">
	<!-- The list of properties -->
	<param name="properties" select="()"/>
	<!-- Are these inverse properties? -->
	<param name="inverse" select="false()"/>

	<!-- The identifier of the current resource -->
	<param name="blank-node"/>
	<param name="generated-blank-node-id"/>
	<param name="generated-uri"/>
	<for-each select="$properties">
	    <if test=".">
		<choose>
		    <when test="$blank-node">
			<call-template name="krextor:add-uri-property">
			    <with-param name="property" select="."/>
			    <with-param name="inverse" select="$inverse"/>
			    <with-param name="blank" select="$generated-blank-node-id"/>
			</call-template>
		    </when>
		    <otherwise>
			<call-template name="krextor:add-uri-property">
			    <with-param name="property" select="."/>
			    <with-param name="inverse" select="$inverse"/>
			    <with-param name="object" select="$generated-uri"/>
			</call-template>
		    </otherwise>
		</choose>
	    </if>
	</for-each>
    </template>

    <xd:doc>
	<xd:short>Creates an RDF resource from the current element</xd:short>
	<xd:detail><p>Creates an RDF resource of some type from the current
		element, and probably creates related triples having this
		resource as a subject or object.  Then, matching extraction
		templates are applied to the child elements.  A call to
		create-resource defines a scope in which the created resource
		is the default subject of any other triple created using these
		templates, unless another resource is created from some child
		element.  The type (i.e. a URI of some class in some ontology)
		has to be specified.</p>
	    <p>This resource is assumed the default subject of all triples
		extracted from descendant elements and attributes using the
		add-literal-property and add-uri-property templates.
		Optionally, a sequence of properties can be passed by which
		this resource is related to the resource created by the
		invoking template (in most cases the resource created from the
		parent XML element).  Additional properties of this resource
		can be passed, if it is not possible to have them generated by
		templates matching some attributes or children of this
		element.</p></xd:detail></xd:doc>
    <template name="krextor:create-resource">
	<param name="subject" select="()" as="xs:string?"/>
	<param name="related-via-properties" select="()" tunnel="yes"/>
	<param name="related-via-inverse-properties" select="()" tunnel="yes"/>
	<param name="type" select="()" as="xs:string*"/>
	<!-- additional properties of this resource, encoded as
	    <krextor:property uri="property-uri" object="object-uri"/>
	    or
	    <krextor:property uri="property-uri">
		object-literal
	    </krextor:property>
	    On literal-valued objects, the attribute @language and @datatype
	    are also allowed.
	    Support for blank node objects is not yet implemented.
	-->
	<param name="properties"/>
	<!-- The node set to which apply-templates is applied -->
	<!-- We also process attributes, as they may contain links to other resources -->
	<param name="process-next" select="*|@*"/>
	<!-- We pass the subject URI as a parameter into templates.  This is because we need to tweak the subject URI when processing transcluded documents; in this case, the transcluding document's URI should still be considered the subject URI, instead of the URI of the transcluded document. -->
	<param name="subject-uri" tunnel="yes"/>
	<!-- If we are to autogenerate the URI for this node, then we call the krextor:generate-uri function to generate one. Note that if you want to use your own URI generation you have to pass your own 
	  1. The fragment URI of this node, if there is an xml:id attribute
	  2. The subject URI (assumed to be the one of the document), if we are at the root node
	  3. Nothing (no RDF will be generated)
	  -->
	<param name="autogenerate-fragment-uri" select="$autogenerate-fragment-uris"/>
	<!-- Is this a blank node? -->
	<param name="blank-node" select="false()"/>
	<param name="this-blank-node-id" select="()" as="xs:string?"/>
	<!-- is the object an RDF collection? -->
	<param name="collection" select="false()"/>

	<variable name="generated-uri" select="if ($blank-node) then $subject-uri
	    else if (exists($subject)) then $subject
	    else if (exists($autogenerate-fragment-uri)) 
		then krextor:generate-uri(., $autogenerate-fragment-uri, $subject-uri)
	    else $subject-uri" as="xs:string?"/>
	<variable name="generated-blank-node" select="$blank-node or $collection"/>
	<!-- TODO introduce auto-blank node if no xml:id given
	     if auto-blank-node isn't desired, skip elements without xml:id altogether -->
	<variable name="generated-blank-node-id" select="
	    if ($generated-blank-node) then
		concat(if ($collection and not(starts-with($this-blank-node-id, 'collection-'))) then 'collection-' else '',
		    if ($this-blank-node-id) then $this-blank-node-id else generate-id())
	    else ''"/>
	<variable name="subject" select="if ($generated-blank-node) then $generated-blank-node-id else $generated-uri"/>
	<variable name="subject-type" select="if ($generated-blank-node) then 'blank' else 'uri'"/>
	<if test="exists($generated-uri)">
	    <if test="not(parent::node() instance of document-node())">
		<!-- Relate this resource to its parent, if it has a parent -->
		<call-template name="krextor:related-via-properties">
		    <with-param name="properties" select="$related-via-properties"/>
		    <with-param name="blank-node" select="$generated-blank-node"/>
		    <with-param name="generated-blank-node-id" select="$generated-blank-node-id"/>
		    <with-param name="generated-uri" select="$generated-uri"/>
		</call-template>
		<call-template name="krextor:related-via-properties">
		    <with-param name="properties" select="$related-via-inverse-properties"/>
		    <with-param name="inverse" select="true()"/>
		    <with-param name="blank-node" select="$generated-blank-node"/>
		    <with-param name="generated-blank-node-id" select="$generated-blank-node-id"/>
		    <with-param name="generated-uri" select="$generated-uri"/>
		</call-template>
	    </if>

	    <!-- Create the triple(s) that instantiates this resource -->
	    <for-each select="$type">
		<call-template name="krextor:output-triple-impl">
		    <with-param name="subject" select="$subject"/>
		    <with-param name="subject-type" select="$subject-type"/>
		    <with-param name="predicate" select="'&rdf;type'"/>
		    <with-param name="object" select="."/>
		    <with-param name="object-type" select="'uri'"/>
		</call-template>
	    </for-each>

	    <!-- Add additional properties to this resource -->
	    <if test="$properties">
		<for-each select="$properties/krextor:property[@uri]">
		    <variable name="object" select="if (@object) then @object
			else if (text()) then text()
			else ''"/>
		    <if test="$object">
			<call-template name="krextor:output-triple-impl">
			    <with-param name="subject" select="$subject"/>
			    <with-param name="subject-type" select="$subject-type"/>
			    <with-param name="predicate" select="@uri"/>
			    <with-param name="object" select="$object"/>
			    <with-param name="object-type" select="if (@object) then 'uri'
				else ''"/>
			    <with-param name="language" select="@language"/>
			    <with-param name="datatype" select="@datatype"/>
			</call-template>
		    </if>
		</for-each>
	    </if>

	    <choose>
		<when test="$collection">
		    <call-template name="krextor:create-collection">
			<with-param name="blank-node-id" select="$generated-blank-node-id" tunnel="yes"/>
			<with-param name="rest" select="$process-next"/>
		    </call-template>
		</when>
		<otherwise>
		    <!-- Process the children of this element, or whichever nodes desired -->
		    <apply-templates select="$process-next">
			<!-- pass on the generated subject URI or blank node ID.  For resolving relative URIs, an appended fragment does
			     not matter, but for generating property triples for this resource it does. -->
			<with-param name="subject-uri" select="$generated-uri" tunnel="yes"/>
			<!-- Pass the information what type this is; this might help to disambiguate triple generation from children of the element that represents the resource of that type. -->
			<with-param name="type" select="$type" tunnel="yes"/>
			<with-param name="blank-node-id" select="$generated-blank-node-id" tunnel="yes"/>
		    </apply-templates>
		</otherwise>
	    </choose>
	</if>
    </template>

    <variable name="krextor:dummy-node">
	<krextor:dummy-node/>
    </variable>

    <xd:doc>we hope that this slightly speeds up search</xd:doc>
    <key name="krextor:resources" match="*" use="resolve-QName(name(), .)"/>

    <xd:doc>Creates a resource from an element for which a mapping to an ontology class has been declared in the variable <code>krextor:resources</code>.</xd:doc>
    <template match="*" mode="krextor:create-resource">
	<choose>
	    <when test="not(empty($krextor:resources))">
		<!-- variant without key: compare local-name and namespace-uri -->
		<variable name="mapping" select="key('krextor:resources',
		    resolve-QName(name(), .),
		    if (not(empty($krextor:resources)))
		    then $krextor:resources
		    else $krextor:dummy-node)"/>
		<!-- we need this to trap the pre-computation of the key hashes -->
		<call-template name="krextor:create-resource">
		    <with-param name="type" select="$mapping/@type"/>
		    <with-param name="related-via-properties" select="$mapping/@related-via-properties" tunnel="yes"/>
		    <with-param name="related-via-inverse-properties" select="$mapping/@related-via-inverse-properties" tunnel="yes"/>
		</call-template>
	    </when>
	    <otherwise>
		<message terminate="yes">No mappings from XML elements to resources declared</message>
	    </otherwise>
	</choose>
    </template>

    <xd:doc>Adds a literal-valued property to the resource in whose
	create-resource scope this template was called.</xd:doc>
    <template name="krextor:add-literal-property">
	<param name="subject-uri" tunnel="yes"/>
	<param name="blank-node-id" tunnel="yes"/>
	<param name="property" as="xs:string*"/>
	<!-- property from incomplete triples -->
	<param name="tunneled-property" as="xs:string*" tunnel="yes"/>
	<!-- TODO consider allowing XML literals here (move code from RDFa here) -->
	<param name="object" select="."/>
	<!-- Is the object a whitespace-separated list or a sequence? -->
	<param name="object-is-list" select="false()" as="xs:boolean"/>
	<!-- Normalize whitespace around the value of the object? -->
	<param name="normalize-space" select="false()" as="xs:boolean"/>
	<param name="language" select="''"/>
	<param name="datatype" select="''"/>
	<variable name="actual-property" select="if (exists($property)) then $property
	    else $tunneled-property"/>
	<choose>
	    <!-- If the "object" is a whitespace-separated list or a sequence of actual objects, we recursively generate one triple for each object. -->
	    <when test="$object-is-list">
		<for-each select="if (count($object) gt 0) 
		    then $object
		    else tokenize($object, '\s+')">
		    <call-template name="krextor:add-literal-property">
			<with-param name="property" select="$actual-property"/>
			<with-param name="object" select="."/>
			<!-- Make sure that we don't run into an infinite loop ;-) -->
			<with-param name="object-is-list" select="false()"/>
		    </call-template>
		</for-each>
	    </when>
	    <otherwise>
		<for-each select="$actual-property">
		    <call-template name="krextor:output-triple-impl">
			<with-param name="subject" select="if ($blank-node-id) then $blank-node-id
			    else $subject-uri"/>
			<with-param name="subject-type" select="if ($blank-node-id) then 'blank'
			    else 'uri'"/>
			<with-param name="predicate" select="."/>
			<with-param name="object" select="if ($normalize-space) then normalize-space($object)
			    else $object"/>
			<with-param name="language" select="$language"/>
			<with-param name="datatype" select="$datatype"/>
		    </call-template>
		</for-each>
	    </otherwise>
	</choose>
    </template>    

    <xd:doc>we hope that this slightly speeds up search</xd:doc>
    <key name="krextor:literal-properties" match="*" use="resolve-QName(name(), .)"/>

    <xd:doc>Creates a literal property from a child element or attribute for which a mapping to an ontology property has been declared in the variable <code>krextor:literal-properties</code>.</xd:doc>
    <template match="*|@*" mode="krextor:add-literal-property">
	<choose>
	    <when test="not(empty($krextor:literal-properties))">
		<!-- variant without key: compare local-name and namespace-uri -->
		<variable name="mapping" select="key('krextor:literal-properties',
		    resolve-QName(name(), .), 
		    if (not(empty($krextor:literal-properties)))
		    then $krextor:literal-properties
		    else $krextor:dummy-node)"/>
		<!-- we need this to trap the pre-computation of the key hashes -->
		<if test=". instance of attribute() and not($mapping/@krextor:attribute)">
		    <message terminate="yes">No mapping found for attribute <copy-of select="."/></message>
		</if>
		<call-template name="krextor:add-literal-property">
		    <with-param name="property" select="$mapping/@property"/>
		    <with-param name="object-is-list" select="boolean($mapping/@list)"/>
		    <with-param name="normalize-space" select="$mapping/@normalize-space"/>
		</call-template>
	    </when>
	    <otherwise>
		<message terminate="yes">No mappings from XML to literal properties declared</message>
	    </otherwise>
	</choose>
    </template>

    <xd:doc>Adds a URI-valued property to the resource in whose
	<code>create-resource</code> scope this template was called.</xd:doc>
    <template name="krextor:add-uri-property">
	<param name="subject-uri" tunnel="yes"/>
	<param name="blank-node-id" tunnel="yes"/>
	<param name="property" as="xs:string*"/>
	<!-- property from incomplete triples -->
	<param name="tunneled-property" as="xs:string*" tunnel="yes"/>
	<!-- Should the property be applied in inverse direction? -->
	<param name="inverse" select="false()"/>
	<!-- inverse information from incomplete triples -->
	<param name="tunneled-inverse" tunnel="yes"/>
	<!-- Is the object a whitespace-separated list or a 
	multi-element sequence?  Use the empty sequence () instead
	of the empty string in order to pass something that is not an object -->
	<param name="object-is-list" select="false()"/>
	<!-- Currently we assume that, if no explicit link target is given, we are either:
	1. in the root element R of an XIncluded document and that a relationship between the parent of the xi:include and the XIncluded document is to be expressed.
	2. or we are in an attribute or a text node or any item of a whitespace-separated list,
	   and a relationship between the current subject URI and the URIref in the attribute value is to be expressed. -->
	<param name="object" select="if (krextor:is-text-or-attribute-or-atomic(.))
	    then if ($object-is-list) then . else resolve-uri(., $subject-uri)
	    (: What is this resolution good for? MMT?
	       Anyway, if needed, we could also resolve each list
	       item by for - in - return :)
	    else if (parent::node() instance of document-node()) then base-uri()
	    else ''"/>
	<!-- node ID, if the object is a blank node -->
	<param name="blank" as="xs:string?"/>
	<if test="($blank or exists($object)) and (exists($property) or exists($tunneled-property))">
	    <variable name="actual-object" select="if ($blank) then $blank
		else $object"/>
	    <variable name="actual-property" select="if (exists($property)) then $property
		else $tunneled-property"/>
	    <variable name="actual-inverse" select="if (exists($property)) then $inverse
		else $tunneled-inverse"/>
	    <choose>
		<!-- If the "object" is a whitespace-separated list of actual objects, we recursively generate one triple for each object. -->
		<when test="$object-is-list">
		    <for-each select="if (count($actual-object) gt 1)
			then $actual-object
			else tokenize($actual-object, '\s+')">
			<call-template name="krextor:add-uri-property">
			    <with-param name="property" select="$actual-property"/>
			    <with-param name="inverse" select="$actual-inverse"/>
			    <!-- Make sure that we don't run into an infinite loop ;-) -->
			    <with-param name="object-is-list" select="false()"/>
			</call-template>
		    </for-each>
		</when>
		<otherwise>
		    <choose>
			<when test="$actual-inverse">
			    <for-each select="$actual-property">
				<call-template name="krextor:output-triple-impl">
				    <with-param name="subject" select="$actual-object"/>
				    <with-param name="subject-type" select="if ($blank) then 'blank' else 'uri'"/>
				    <with-param name="predicate" select="."/>
				    <with-param name="object" select="if ($blank-node-id) then $blank-node-id
					else $subject-uri"/>
				    <with-param name="object-type" select="if ($blank-node-id) then 'blank'
					else 'uri'"/>
				</call-template>
			    </for-each>
			</when>
			<otherwise>
			    <for-each select="$actual-property">
				<call-template name="krextor:output-triple-impl">
				    <with-param name="subject" select="if ($blank-node-id) then $blank-node-id
					else $subject-uri"/>
				    <with-param name="subject-type" select="if ($blank-node-id) then 'blank'
					else 'uri'"/>
				    <with-param name="predicate" select="."/>
				    <with-param name="object" select="$actual-object"/>
				    <with-param name="object-type" select="if ($blank) then 'blank' else 'uri'"/>
				</call-template>
			    </for-each>
			</otherwise>
		    </choose>
		</otherwise>
	    </choose>
	</if>
    </template>    

    <xd:doc>Creates a property whose values are added by nested template calls</xd:doc>
    <template name="krextor:create-property">
	<param name="property" required="yes"/>
	<param name="inverse" select="false()"/>
	<!-- The node set to which apply-templates is applied -->
	<!-- We also process attributes, as they may contain links to other resources -->
	<param name="process-next" select="*|@*"/>
	<apply-templates select="$process-next">
	    <with-param name="tunneled-property" select="$property" tunnel="yes"/>
	    <with-param name="tunneled-inverse" select="$inverse" tunnel="yes"/>
	</apply-templates>
    </template>

    <xd:doc>Creates an rdf Collection</xd:doc>
    <template name="krextor:create-collection">
	<param name="rest"/>
	<param name="blank-node-id" tunnel="yes"/>
	<param name="collection-id" select="()" tunnel="yes"/>
	<param name="collection-index" select="1" tunnel="yes"/>
	<variable name="new-collection-id" select="if (exists($collection-id)) then $collection-id else $blank-node-id"/>
	<variable name="subject" select="concat($new-collection-id, '-', $collection-index)"/>
	<apply-templates select="$rest[1]">
	    <with-param name="blank-node-id" select="$blank-node-id" tunnel="yes"/>
	    <!-- if a resource is created from the first element, make it the first resource of this collection -->
	    <with-param name="related-via-properties" select="'&rdf;first'" tunnel="yes"/>
	</apply-templates>    	
    	
	<choose>
	    <when test="$rest[2]">
		<call-template name="krextor:create-resource">
		    <with-param name="blank-node-id" select="$blank-node-id" tunnel="yes"/>
		    <with-param name="this-blank-node-id" select="$subject"/>
		    <with-param name="related-via-properties" select="'&rdf;rest'" tunnel="yes"/>
		    <with-param name="collection" select="true()"/>
		    <with-param name="process-next" select="$rest[position() ge 2]"/>
		    <with-param name="collection-id" select="$new-collection-id" tunnel="yes"/>
		    <with-param name="collection-index" select="$collection-index + 1" tunnel="yes"/>
		</call-template>
	    </when>
	    <otherwise>
		<call-template name="krextor:create-resource">
		    <with-param name="subject-uri" select="'&rdf;nil'" tunnel="yes"/>
		    <with-param name="related-via-properties" select="'&rdf;rest'" tunnel="yes"/>
		    <with-param name="process-next" select="()"/>
		</call-template>
	    </otherwise>
	</choose>
    </template>

    <xd:doc>
	<xd:short>Follows an XInclude (generally supported by Krextor)</xd:short>
	<xd:detail>
	    <p>Krextor supports the following generic inclusion mechanism for XML documents: A root element R of a transcluded documents will be treated like a direct child of the parent element P of the xi:include element.  If there is a relevant relationship between P and R, an according triple is generated, with the transcluded document's URI (not the URI of R!) being the object.  The transcluded document is loaded and its root node examined in order to find this out.  Any relationships between elements of the transcluding document and the transcluded document that are not direct relationships between P and R are not considered during RDF extraction.</p>
	    <p>Note: We're using XInclude because the semantics of <![CDATA[<element xlink:type="simple" xlink:show="embed" xlink:href="some-XML-resource"/>]]> is not yet clearly defined in the XLink specification.  Should the root element of the document pointed to replace the pointing element, or should it be transcluded into the pointing element as a child?</p>
	</xd:detail>
    </xd:doc>
    <template match="xi:include">
	<if test="$traverse-xincludes">
	    <apply-templates select="document(@href, .)" mode="krextor:included">
		<with-param name="krextor:parent-element" select="." tunnel="yes"/>
	    </apply-templates>
	</if>
    </template>

    <xd:doc>Process the root element of an XIncluded document</xd:doc>
    <template match="/" mode="krextor:included">
	<apply-templates mode="krextor:included"/>
    </template>

    <xd:doc>Start processing; the current subject is identified by the base URI of the document.</xd:doc>
    <template match="/">
	<param name="krextor:base-uri" select="base-uri()" tunnel="yes"/>
	<apply-templates>
	    <with-param name="subject-uri" select="$krextor:base-uri" tunnel="yes"/>
	    <with-param name="krextor:base-uri" select="$krextor:base-uri" tunnel="yes"/>
	</apply-templates>
    </template>

    <xd:doc>Do not extract RDF from attributes that are not matched by the
	language-specific templates, no from text nodes.</xd:doc>
    <template match="@*|text()"/>

    <xd:doc>Do not extract RDF from attributes that are not matched by the
	language-specific templates, no from text nodes (same for XIncluded documents).</xd:doc>
    <template match="@*|text()" mode="krextor:included"/>
</stylesheet>

