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

<!DOCTYPE stylesheet [
    <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
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
<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" 
    xmlns:krextor="http://kwarc.info/projects/krextor"
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

	 Also note that any fragment ID that the base URI of the document
	 already has is discarded and replaced by the generated fragment ID, if
	 Krextor is instructed to generate one.  More than one fragment is not
	 allowed by the URI RFC 3986 (http://www.faqs.org/rfcs/rfc3986.html).
	 See
	 http://www.aifb.uni-karlsruhe.de/pipermail/swikig/2006-February/000095.html
	 for more background on this in a semantic web context.
    -->
    <param name="autogenerate-fragment-uris" select="('xml-id',
	'document-root-base')"/>

    <!-- Should XIncludes be traversed?  Note: Templates for nodes in XIncluded
         documents are matched in "krextor:included" mode. -->
    <param name="traverse-xincludes" select="true()"/>

    <variable name="krextor:resources" select="()"/>
    <variable name="krextor:literal-properties" select="()"/>

    <!-- Checks whether a given node is a text node, an attribute, or an atomic value -->
    <function name="krextor:is-text-or-attribute-or-atomic">
	<param name="node"/>
	<sequence select="$node instance of xs:anyAtomicType
	    or $node instance of text()
	    or $node instance of attribute()"/>
    </function>

    <!-- Generates a URI for a fragment of a document; returns the empty sequence if the fragment ID is empty -->
    <function name="krextor:fragment-uri-or-null">
	<param name="fragment-id"/>
	<param name="base-uri"/>
	<value-of select="if ($fragment-id)
	    then resolve-uri(concat('#', $fragment-id), $base-uri)
	    else ()"/>
    </function>

    <!-- creates an XPath-like string from the path to a node, 
         e.g. doc-sect1-para2 for /doc/sect[1]/para[2] -->
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

    <!-- Generates a URI for a resource -->
    <function name="krextor:generate-uri">
	<param name="node"/>
	<param name="position"/>
	<param name="autogenerate-fragment-uri"/>
	<param name="base-uri"/>
	<value-of select="krextor:generate-uri-step(
	    $node,
	    $position,
	    $base-uri,
	    $autogenerate-fragment-uri[1],
	    subsequence($autogenerate-fragment-uri, 2))"/>
    </function>

    <!-- Generates a URI for a resource: head/tail implementation of a single step -->
    <!-- TODO revise this using fxsl -->
    <function name="krextor:generate-uri-step">
	<param name="node"/>
	<param name="position"/>
	<param name="base-uri"/>
	<param name="head"/>
	<param name="tail"/>

	<variable name="result" select="
	    if ($head eq 'document-root-base'
		and $node/parent::node() instance of document-node())
		then $base-uri
	    else if ($head = ('xml-id', 'generate-id', 'pseudo-xpath'))
		then krextor:fragment-uri-or-null(
		    if ($head eq 'xml-id' and $node/@xml:id)
		        then $node/@xml:id
		    else if ($head eq 'generate-id')
			then generate-id($node) 
		    else if ($head eq 'pseudo-xpath')
			then krextor:pseudo-xpath($node)
		    else (),
		    $base-uri)
	    else ()"/>
	<value-of select="if ($result) then $result
	    else if (exists($tail)) then krextor:generate-uri-step(
		$node,
		$position,
		$base-uri,
		$tail[1],
		subsequence($tail, 2)
	    )
	    else ()"/>
    </function>

    <!-- Relates the current resource to its parent via some properties or their inverses -->
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
    add-uri-property templates.  Optionally, a sequence of properties can be
    passed by which this resource is related to the resource created by the
    invoking template (in most cases the resource created from the parent XML
    element).  Additional properties of this resource can be passed, if it is
    not possible to have them generated by templates matching some attributes
    or children of this element.
    -->
    <template name="krextor:create-resource">
	<param name="subject"/>
	<param name="related-via-properties" select="()"/>
	<param name="related-via-inverse-properties" select="()"/>
	<param name="type" select="()"/>
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
	<!-- We pass the base URI as a parameter into templates.  This is because we need to tweak the base URI when processing transcluded documents; in this case, the transcluding document's URI should still be considered the base URI, instead of the URI of the transcluded document. -->
	<param name="base-uri" tunnel="yes"/>
	<!-- If we are to autogenerate the URI for this node, then we call the krextor:generate-uri function to generate one. Note that if you want to use your own URI generation you have to pass your own 
	  1. The fragment URI of this node, if there is an xml:id attribute
	  2. The base URI (assumed to be the one of the document), if we are at the root node
	  3. Nothing (no RDF will be generated)
	  -->
	<param name="autogenerate-fragment-uri" select="$autogenerate-fragment-uris"/>
	<!-- Is this a blank node? -->
	<param name="blank-node" select="false()"/>
	<param name="blank-node-id" tunnel="yes"/>
	<variable name="generated-uri" select="if ($blank-node) then $base-uri
	    else if ($subject) then $subject
	    else if (exists($autogenerate-fragment-uri)) 
		then krextor:generate-uri(., position(), $autogenerate-fragment-uri, $base-uri)
	    else $base-uri"/>
	<!-- TODO introduce auto-blank node if no xml:id given
	     if auto-blank-node isn't desired, skip elements without xml:id altogether -->
	<variable name="generated-blank-node-id" select="if ($blank-node) then generate-id()
	    else ''"/>
	<variable name="subject" select="if ($blank-node) then $generated-blank-node-id else $generated-uri"/>
	<variable name="subject-type" select="if ($blank-node) then 'blank' else 'uri'"/>
	<if test="$generated-uri">
	    <!-- Create the triple(s) that instantiates this resource -->
	    <for-each select="$type">
		<call-template name="krextor:output-triple">
		    <with-param name="subject" select="$subject"/>
		    <with-param name="subject-type" select="$subject-type"/>
		    <with-param name="predicate" select="'&rdf;type'"/>
		    <with-param name="object" select="."/>
		    <with-param name="object-type" select="'uri'"/>
		</call-template>
	    </for-each>

	    <if test="not(parent::node() instance of document-node())">
		<!-- Relate this resource to its parent, if it has a parent -->
		<call-template name="krextor:related-via-properties">
		    <with-param name="properties" select="$related-via-properties"/>
		    <with-param name="blank-node" select="$blank-node"/>
		    <with-param name="generated-blank-node-id" select="$generated-blank-node-id"/>
		    <with-param name="generated-uri" select="$generated-uri"/>
		</call-template>
		<call-template name="krextor:related-via-properties">
		    <with-param name="properties" select="$related-via-inverse-properties"/>
		    <with-param name="inverse" select="true()"/>
		    <with-param name="blank-node" select="$blank-node"/>
		    <with-param name="generated-blank-node-id" select="$generated-blank-node-id"/>
		    <with-param name="generated-uri" select="$generated-uri"/>
		</call-template>
	    </if>

	    <!-- Add additional properties to this resource -->
	    <if test="$properties">
		<for-each select="$properties/krextor:property[@uri]">
		    <variable name="object" select="if (@object) then @object
			else if (text()) then text()
			else ''"/>
		    <if test="$object">
			<call-template name="krextor:output-triple">
			    <with-param name="subject" select="$subject"/>
			    <with-param name="subject-type" select="$subject-type"/>
			    <with-param name="predicate" select="@uri"/>
			    <with-param name="object" select="$object"/>
			    <with-param name="object-type" select="if (@object) then 'uri'
				else ''"/>
			    <with-param name="object-language" select="@language"/>
			    <with-param name="object-datatype" select="@datatype"/>
			</call-template>
		    </if>
		</for-each>
	    </if>

	    <!-- Process the children of this element, or whichever nodes desired -->
	    <apply-templates select="$process-next">
		<!-- pass on the generated base URI or blank node ID.  For resolving relative URIs, an appended fragment does
		     not matter, but for generating property triples for this resource it does. -->
		<with-param name="base-uri" select="$generated-uri" tunnel="yes"/>
		<!-- Pass the information what type this is; this might help to disambiguate triple generation from children of the element that represents the resource of that type. -->
		<with-param name="type" select="$type" tunnel="yes"/>
		<with-param name="blank-node-id" select="$generated-blank-node-id" tunnel="yes"/>
	    </apply-templates>
	</if>
    </template>

    <template match="*" mode="krextor:create-resource">
	<variable name="mapping" select="$krextor:resources/*[
		    local-name() eq local-name(current())
		    and namespace-uri() eq namespace-uri(current())]"/>
	<call-template name="krextor:create-resource">
	    <with-param name="type" select="$mapping/@type"/>
	    <with-param name="related-via-properties" select="$mapping/@related-via-properties"/>
	    <with-param name="related-via-inverse-properties" select="$mapping/@related-via-inverse-properties"/>
	</call-template>
    </template>

    <!-- Adds a literal-valued property to the resource in whose
         create-resource scope this template was called. -->
    <template name="krextor:add-literal-property">
	<param name="base-uri" tunnel="yes"/>
	<param name="blank-node-id" tunnel="yes"/>
	<param name="property"/>
	<!-- property from incomplete triples -->
	<param name="tunneled-property" tunnel="yes"/>
	<param name="object" select="."/>
	<!-- Is the object a whitespace-separated list? -->
	<param name="list" select="false()" as="xs:boolean"/>
	<!-- Normalize whitespace around the value of the object? -->
	<param name="normalize-space" select="false()" as="xs:boolean"/>
	<param name="object-language" select="''"/>
	<param name="object-datatype" select="''"/>
	<variable name="actual-property" select="if ($property) then $property
	    else $tunneled-property"/>
	<choose>
	    <!-- If the "object" is a whitespace-separated list of actual objects, we recursively generate one triple for each object. -->
	    <when test="$list">
		<for-each select="tokenize($object, '\s+')">
		    <call-template name="krextor:add-literal-property">
			<with-param name="property" select="$actual-property"/>
			<with-param name="object" select="."/>
			<!-- Make sure that we don't run into an infinite loop ;-) -->
			<with-param name="list" select="false()"/>
		    </call-template>
		</for-each>
	    </when>
	    <otherwise>
		<call-template name="krextor:output-triple">
		    <with-param name="subject" select="if ($blank-node-id) then $blank-node-id
			else $base-uri"/>
		    <with-param name="subject-type" select="if ($blank-node-id) then 'blank'
			else 'uri'"/>
		    <with-param name="predicate" select="$actual-property"/>
		    <with-param name="object" select="if ($normalize-space) then normalize-space($object)
			else $object"/>
		    <with-param name="object-language" select="$object-language"/>
		    <with-param name="object-datatype" select="$object-datatype"/>
		</call-template>
	    </otherwise>
	</choose>
    </template>    

    <template match="*|@*" mode="krextor:add-literal-property">
	<variable name="mapping" select="$krextor:literal-properties/*[
		    local-name() eq local-name(current())
		    and namespace-uri() eq namespace-uri(current())
		    and (not(current() instance of attribute()) or @krextor-attribute)]"/>
	<call-template name="krextor:add-literal-property">
	    <with-param name="property" select="$mapping/@property"/>
	    <with-param name="list" select="boolean($mapping/@list)"/>
	    <with-param name="normalize-space" select="$mapping/@normalize-space"/>
	</call-template>
    </template>

    <!-- Adds a URI-valued property to the resource in whose create-resource
         scope this template was called. -->
    <template name="krextor:add-uri-property">
	<param name="base-uri" tunnel="yes"/>
	<param name="blank-node-id" tunnel="yes"/>
	<param name="property"/>
	<!-- property from incomplete triples -->
	<param name="tunneled-property" tunnel="yes"/>
	<!-- Should the property be applied in inverse direction? -->
	<param name="inverse" select="false()"/>
	<!-- inverse information from incomplete triples -->
	<param name="tunneled-inverse" tunnel="yes"/>
	<!-- Is the object a whitespace-separated list? -->
	<param name="list" select="false()"/>
	<!-- Currently we assume that, if no explicit link target is given, we are either:
	1. in the root element R of an XIncluded document and that a relationship between the parent of the xi:include and the XIncluded document is to be expressed.
	2. or we are in an attribute or a text node or any item of a whitespace-separated list,
	   and a relationship between the current base URI and the URIref in the attribute value is to be expressed. -->
	<param name="object" select="if (krextor:is-text-or-attribute-or-atomic(.))
	       then if ($list) then . else resolve-uri(., $base-uri)
	    else if (parent::node() instance of document-node()) then base-uri()
	    else ''"/>
	<!-- node ID, if the object is a blank node -->
	<param name="blank"/>
	<if test="($blank or $object) and ($property or $tunneled-property)">
	    <variable name="actual-object" select="if ($blank) then $blank
		else $object"/>
	    <variable name="actual-property" select="if ($property) then $property
		else $tunneled-property"/>
	    <variable name="actual-inverse" select="if ($property) then $inverse
		else $tunneled-inverse"/>
	    <choose>
		<!-- If the "object" is a whitespace-separated list of actual objects, we recursively generate one triple for each object. -->
		<when test="$list">
		    <for-each select="tokenize($actual-object, '\s+')">
			<call-template name="krextor:add-uri-property">
			    <with-param name="property" select="$actual-property"/>
			    <with-param name="inverse" select="$actual-inverse"/>
			    <!-- Make sure that we don't run into an infinite loop ;-) -->
			    <with-param name="list" select="false()"/>
			</call-template>
		    </for-each>
		</when>
		<otherwise>
		    <choose>
			<when test="$actual-inverse">
			    <call-template name="krextor:output-triple">
				<with-param name="subject" select="$actual-object"/>
				<with-param name="subject-type" select="if ($blank) then 'blank' else 'uri'"/>
				<with-param name="predicate" select="$actual-property"/>
				<with-param name="object" select="if ($blank-node-id) then $blank-node-id
				    else $base-uri"/>
				<with-param name="object-type" select="if ($blank-node-id) then 'blank'
				    else 'uri'"/>
			    </call-template>
			</when>
			<otherwise>
			    <call-template name="krextor:output-triple">
				<with-param name="subject" select="if ($blank-node-id) then $blank-node-id
				    else $base-uri"/>
				<with-param name="subject-type" select="if ($blank-node-id) then 'blank'
				    else 'uri'"/>
				<with-param name="predicate" select="$actual-property"/>
				<with-param name="object" select="$actual-object"/>
				<with-param name="object-type" select="if ($blank) then 'blank' else 'uri'"/>
			    </call-template>
			</otherwise>
		    </choose>
		</otherwise>
	    </choose>
	</if>
    </template>    

    <!-- Creates a property whose values are added by nested template calls -->
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

    <!-- We support the following generic inclusion mechanism for XML documents:
    A root element R of a transcluded documents will be treated like a direct child of the parent element P of the xi:include element.  If there is a relevant relationship between P and R, an according triple is generated, with the transcluded document's URI (not the URI of R!) being the object.  The transcluded document is loaded and its root node examined in order to find this out.  Any relationships between elements of the transcluding document and the transcluded document that are not direct relationships between P and R are not considered during RDF extraction.

    Note: We're using XInclude because the semantics of <element xlink:type="simple" xlink:show="embed" xlink:href="some-XML-resource"/> is not yet clearly defined in the XLink specification.  Should the root element of the document pointed to replace the pointing element, or should it be transcluded into the pointing element as a child?
    -->
    <template match="xi:include">
	<if test="$traverse-xincludes">
	    <apply-templates select="document(@href, .)" mode="krextor:included">
		<with-param name="krextor:parent-element" select="." tunnel="yes"/>
	    </apply-templates>
	</if>
    </template>

    <template match="/" mode="krextor:included">
	<apply-templates mode="krextor:included"/>
    </template>

    <template match="/">
	<apply-templates>
	    <with-param name="base-uri" select="base-uri()" tunnel="yes"/>
	</apply-templates>
    </template>

    <!-- No RDF is extracted from attributes that are not matched by the
	 language-specific templates, nor from text nodes. -->
    <template match="@*|text()"/>
    <template match="@*|text()" mode="krextor:included"/>
</stylesheet>

