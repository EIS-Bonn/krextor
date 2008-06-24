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
    <xsl:param name="autogenerate-fragment-uris" select="true()"/>

    <!-- Checks whether a given node is a text node, an attribute, or an atomic value
         Credits to http://www.dpawson.co.uk/xsl/sect2/nodetest.html#d8319e91 -->
    <xsl:function name="krextor:is-text-or-attribute-or-atomic">
	<xsl:param name="node"/>
	<!-- Need to test for atomic types separately, as otherwise the node tests below would fail.
	     Can't put both tests into one XPath boolean expression as XPath does
	     type checking before (lazy) evaluation. -->
	<xsl:sequence select="if ($node instance of xs:anyAtomicType)
	    then true()
	    else $node/text() or (count($node | $node/../@*) eq count($node/../@*))"/>
    </xsl:function>

    <!--
    Starts triple creation for a resource extracted from the current element.
    The type (i.e. a URI of some class in some ontology) has to be specified.
    This resource is assumed the default subject of all triples extracted from
    descendant elements and attributes using the add-literal-property and
    add-uri-property templates.  Optionally, a property can be passed by which 
    this resource is related to the resource created by the invoking template
    (in most cases the resource created from the parent XML element)
    -->
    <xsl:template name="create-resource">
	<xsl:param name="related-via-property"/>
	<xsl:param name="type"/>
	<!-- We pass the base URI as a parameter into templates.  This is because we need to tweak the base URI when processing transcluded documents; in this case, the transcluding document's URI should still be considered the base URI, instead of the URI of the transcluded document. -->
	<xsl:param name="base-uri" tunnel="yes"/>
	<!-- If we are to autogenerate the URI for this node (i.e. if no manipulated base URI has been passed in and should be used), then a URI for this node is generated as follows:
	  1. The fragment URI of this node, if there is an xml:id attribute
	  2. The base URI (assumed to be the one of the document), if we are at the root node
	  3. Nothing (no RDF will be generated)
	  -->
	<xsl:param name="autogenerate-fragment-uri" select="$autogenerate-fragment-uris"/>
	<xsl:variable name="generated-uri" select="if ($autogenerate-fragment-uri) then
		if (@xml:id) then resolve-uri(concat('#', @xml:id), $base-uri)
		else if (self::node() = /) then $base-uri
		else ()
	    else $base-uri"/>
	<xsl:if test="$generated-uri">
	    <xsl:if test="$related-via-property">
		<xsl:call-template name="add-uri-property">
		    <xsl:with-param name="property" select="$related-via-property"/>
		    <xsl:with-param name="object" select="$generated-uri"/>
		</xsl:call-template>
	    </xsl:if>
	    <xsl:sequence select="krextor:triple-uri($generated-uri, '&rdf;type', $type)"/>
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

    <!-- Adds a literal property for the currently active subject (see
         create-resource) -->
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

    <!-- Adds a URI property for the currently active subject (see
    create-resource) -->
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
	    else if (self::node() = /) then base-uri()
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
	<xsl:apply-templates select="document(@href, .)" mode="included"/>
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

