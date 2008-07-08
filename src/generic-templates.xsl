<?xml version="1.0" encoding="UTF-8"?>

<!--
    *  Copyright (C) 2008
    *  Christoph Lange
    *  Jacobs University Bremen
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

<!DOCTYPE xsl:stylesheet [
    <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY lang "http://purl.org/dc/elements/1.1/language#">
]>

<!--
This stylesheet provides convenience functions and templates for an RDF
extraction from XML languages.  It is independent of any RDF output notation.

So far the extraction only works on the toplevel of a document, a restriction
influenced by the setting of a semantic wiki, namely SWiM.

TODO but sub-pagelevel resources should also be supported, just with the GUI
support being a bit restricted. I.e. that you can jump to them (the whole page
would be loaded and the respective fragment shown), but you would e.g. not see
relationships between fragments in the "references" portlet.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:krextor="http://kwarc.info/projects/krextor/"
    xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="krextor xi xs"
    version="2.0">
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
    -->
    <xsl:param name="autogenerate-fragment-uris" select="('xml-id',
	'document-root-base')"/>

    <!-- Should XIncludes be traversed?  Note: Templates for nodes in XIncluded
         documents are matched in "included" mode. -->
    <xsl:param name="traverse-xincludes" select="true()"/>

    <!-- Checks whether a given node is a text node, an attribute, or an atomic value -->
    <xsl:function name="krextor:is-text-or-attribute-or-atomic">
	<xsl:param name="node"/>
	<xsl:sequence select="$node instance of xs:anyAtomicType
	    or $node instance of text()
	    or $node instance of attribute()"/>
    </xsl:function>

    <xsl:function name="krextor:fragment-uri">
	<xsl:param name="fragment-id"/>
	<xsl:param name="base-uri"/>
	<xsl:value-of select="resolve-uri(concat('#', $fragment-id), $base-uri)"/>
    </xsl:function>

    <xsl:function name="krextor:pseudo-xpath">
	<xsl:param name="node"/>
	<xsl:value-of select="if ($node/parent::node() instance of document-node())
		then local-name($node)
	    else concat(
		krextor:pseudo-xpath($node/parent::node()),
		'-',
		local-name($node),
		count($node/preceding-sibling::node()) + 1
		)"/>
    </xsl:function>

    <!-- Generates a URI for a resource -->
    <xsl:function name="krextor:generate-uri">
	<xsl:param name="node"/>
	<xsl:param name="position"/>
	<xsl:param name="autogenerate-fragment-uri"/>
	<xsl:param name="base-uri"/>
	<xsl:value-of select="krextor:generate-uri-step(
	    $node,
	    $position,
	    $base-uri,
	    $autogenerate-fragment-uri[1],
	    subsequence($autogenerate-fragment-uri, 2))"/>
    </xsl:function>

    <!-- Generates a URI for a resource: head/tail implementation of a single step -->
    <xsl:function name="krextor:generate-uri-step">
	<xsl:param name="node"/>
	<xsl:param name="position"/>
	<xsl:param name="base-uri"/>
	<xsl:param name="head"/>
	<xsl:param name="tail"/>

	<xsl:variable name="result" select="
	    if ($head eq 'document-root-base'
		and $node/parent::node() instance of document-node())
		then $base-uri
	    else if ($head = ('xml-id', 'generate-id', 'pseudo-xpath'))
		then krextor:fragment-uri(
		    if ($head eq 'xml-id' and $node/@xml:id)
		        then $node/@xml:id
		    else if ($head eq 'generate-id')
			then generate-id($node) 
		    else if ($head eq 'pseudo-xpath')
			then krextor:pseudo-xpath($node)
		    else (),
		    $base-uri)
	    else ()"/>
	<xsl:value-of select="if ($result) then $result
	    else if (exists($tail)) then krextor:generate-uri-step(
		$node,
		$position,
		$base-uri,
		$tail[1],
		subsequence($tail, 2)
	    )
	    else ()"/>
    </xsl:function>

    <!--
    Creates an RDF resource of some type from the current element, and probably
    creates related triples having this resource as a subject or object.  Then,
    matching extraction templates are applied to the child elements.  A call to
    create-resource defines a scope in which the created resource is the
    default subject of any other triple created using these templates, unless
    another resource is created from some child element.

    The type (i.e. a URI of some class in some ontology) has to be specified.
    This resource is assumed the default subject of all triples extracted from
    descendant elements and attributes using the add-literal-property and
    add-uri-property templates.  Optionally, a property can be passed by which
    this resource is related to the resource created by the invoking template
    (in most cases the resource created from the parent XML element).
    Additional properties of this resource can be passed, if it is not possible
    to have them generated by templates matching some attributes or children of
    this element.
    -->
    <xsl:template name="create-resource">
	<xsl:param name="related-via-property"/>
	<xsl:param name="type"/>
	<!-- additional properties of this resource, encoded as
	    <krextor:property uri="property-uri" object="object-uri"/>
	    or
	    <krextor:property uri="property-uri">
		object-literal
	    </krextor:property>
	-->
	<xsl:param name="properties"/>
	<!-- We pass the base URI as a parameter into templates.  This is because we need to tweak the base URI when processing transcluded documents; in this case, the transcluding document's URI should still be considered the base URI, instead of the URI of the transcluded document. -->
	<xsl:param name="base-uri" tunnel="yes"/>
	<!-- If we are to autogenerate the URI for this node, then we call the krextor:generate-uri function to generate one. Note that if you want to use your own URI generation you have to pass your own 
	  1. The fragment URI of this node, if there is an xml:id attribute
	  2. The base URI (assumed to be the one of the document), if we are at the root node
	  3. Nothing (no RDF will be generated)
	  -->
	<xsl:param name="autogenerate-fragment-uri" select="$autogenerate-fragment-uris"/>
	<xsl:variable name="generated-uri" select="if (exists($autogenerate-fragment-uri)) 
	    then krextor:generate-uri(., position(), $autogenerate-fragment-uri, $base-uri)
	    else $base-uri"/>
	<xsl:if test="$generated-uri">
	    <xsl:sequence select="krextor:triple-uri($generated-uri, '&rdf;type', $type)"/>
	    <xsl:if test="$related-via-property">
		<xsl:call-template name="add-uri-property">
		    <xsl:with-param name="property" select="$related-via-property"/>
		    <xsl:with-param name="object" select="$generated-uri"/>
		</xsl:call-template>
	    </xsl:if>
	    <xsl:if test="$properties">
		<xsl:for-each select="$properties/krextor:property[@uri]">
		    <xsl:sequence select="if (@object) 
			then krextor:triple-uri($generated-uri, @uri, @object)
			else if (text()) then krextor:triple-lit($generated-uri, @uri, text())
			else ()"/>
		</xsl:for-each>
	    </xsl:if>
	    <!-- We also process attributes, as they may contain links to other resources -->
	    <xsl:apply-templates select="*|@*">
		<!-- pass on the generated base URI.  For resolving relative URIs, an appended fragment does
		     not matter, but for generating property triples for this resource it does. -->
		<xsl:with-param name="base-uri" select="$generated-uri" tunnel="yes"/>
		<!-- Pass the information what type this is; this might help to disambiguate triple generation from children of the element that represents the resource of that type. -->
		<xsl:with-param name="type" select="$type" tunnel="yes"/>
	    </xsl:apply-templates>
	</xsl:if>
    </xsl:template>

    <!-- Adds a literal-valued property to the resource in whose
         create-resource scope this template was called. -->
    <xsl:template name="add-literal-property">
	<xsl:param name="property"/>
	<xsl:param name="base-uri" tunnel="yes"/>
	<xsl:param name="object" select="."/>
	<!-- Is the object a whitespace-separated list? -->
	<xsl:param name="list" select="false()"/>
	<!-- Normalize whitespace around the value of the object? -->
	<xsl:param name="normalize-space" select="false()"/>
	<xsl:choose>
	    <!-- If the "object" is a whitespace-separated list of actual objects, we recursively generate one triple for each object. -->
	    <xsl:when test="$list">
		<xsl:for-each select="tokenize($object, '\s+')">
		    <xsl:call-template name="add-literal-property">
			<xsl:with-param name="property" select="$property"/>
			<xsl:with-param name="object" select="."/>
			<!-- Make sure that we don't run into an infinite loop ;-) -->
			<xsl:with-param name="list" select="false()"/>
		    </xsl:call-template>
		</xsl:for-each>
	    </xsl:when>
	    <xsl:otherwise>
		<xsl:sequence select="krextor:triple-lit($base-uri, $property, if ($normalize-space) then normalize-space($object) else $object)"/>
	    </xsl:otherwise>
	</xsl:choose>
    </xsl:template>    

    <!-- Adds a URI-valued property to the resource in whose create-resource
         scope this template was called. -->
    <xsl:template name="add-uri-property">
	<xsl:param name="base-uri" tunnel="yes"/>
	<xsl:param name="property"/>
	<!-- Is the object a whitespace-separated list? -->
	<xsl:param name="list" select="false()"/>
	<!-- Currently we assume that, if no explicit link target is given, we are either:
	1. in the root element R of an XIncluded document and that a relationship between the parent of the xi:include and the XIncluded document is to be expressed.
	2. or we are in an attribute or a text node or any item of a whitespace-separated list,
	   and a relationship between the current base URI and the URIref in the attribute value is to be expressed. -->
	<xsl:param name="object" select="if (krextor:is-text-or-attribute-or-atomic(.))
	       then if ($list) then . else resolve-uri(., $base-uri)
	    else if (parent::node() instance of document-node()) then base-uri()
	    else ()"/>
	<xsl:if test="$object">
	    <xsl:choose>
		<!-- If the "object" is a whitespace-separated list of actual objects, we recursively generate one triple for each object. -->
		<xsl:when test="$list">
		    <xsl:for-each select="tokenize($object, '\s+')">
			<xsl:call-template name="add-uri-property">
			    <xsl:with-param name="property" select="$property"/>
			    <!-- Make sure that we don't run into an infinite loop ;-) -->
			    <xsl:with-param name="list" select="false()"/>
			</xsl:call-template>
		    </xsl:for-each>
		</xsl:when>
		<xsl:otherwise>
		    <xsl:sequence select="krextor:triple-uri($base-uri, $property, $object)"/>
		</xsl:otherwise>
	    </xsl:choose>
	</xsl:if>
    </xsl:template>    
	

    <!-- We support the following generic inclusion mechanism for XML documents:
    A root element R of a transcluded documents will be treated like a direct child of the parent element P of the xi:include element.  If there is a relevant relationship between P and R, an according triple is generated, with the transcluded document's URI (not the URI of R!) being the object.  The transcluded document is loaded and its root node examined in order to find this out.  Any relationships between elements of the transcluding document and the transcluded document that are not direct relationships between P and R are not considered during RDF extraction.

    Note: We're using XInclude because the semantics of <element xlink:type="simple" xlink:show="embed" xlink:href="some-XML-resource"/> is not yet clearly defined in the XLink specification.  Should the root element of the document pointed to replace the pointing element, or should it be transcluded into the pointing element as a child?
    -->
    <xsl:template match="xi:include">
	<xsl:if test="$traverse-xincludes">
	    <xsl:apply-templates select="document(@href, .)" mode="included"/>
	</xsl:if>
    </xsl:template>

    <xsl:template match="/" mode="included">
	<xsl:apply-templates mode="included"/>
    </xsl:template>

    <xsl:template match="/">
	<xsl:apply-templates>
	    <xsl:with-param name="base-uri" select="base-uri()" tunnel="yes"/>
	</xsl:apply-templates>
    </xsl:template>

    <!-- No RDF is extracted from attributes that are not matched by the
	 language-specific templates, nor from text nodes. -->
    <xsl:template match="@*|text()"/>
</xsl:stylesheet>

