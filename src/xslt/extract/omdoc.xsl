<?xml version="1.0" encoding="UTF-8"?>

<!--
    *  Copyright (C) 2008
    *  Christoph Lange
    *  Gordan Ristovski
    *  Andrei Ioniţă
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
    <!ENTITY odo "http://omdoc.org/ontology#">
    <!ENTITY dc "http://purl.org/dc/elements/1.1/">
    <!ENTITY sdoc "http://salt.semanticauthoring.org/onto/abstract-document-ontology#">
    <!ENTITY sr "http://salt.semanticauthoring.org/onto/rhetorical-ontology#">
]>

<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" 
    xpath-default-namespace="http://omdoc.org/ns"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    xmlns:omdoc="http://omdoc.org/ns"
    xmlns:om="http://www.openmath.org/OpenMath"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="#all"
    version="2.0">

    <import href="util/omdoc.xsl"/>

    <xd:doc type="stylesheet">
	<xd:short>Extraction module for <a href="http://www.omdoc.org">OMDoc</a></xd:short>
	<xd:detail>
	    <p>This stylesheet extracts RDF from <a href="http://www.omdoc.org">OpenMath</a> content dictionaries (CDs).</p>  
	    <p>Existing metadata vocabularies are reused, as documented here or in the ontology.</p>
	    <p>See <a href="https://svn.omdoc.org/repos/omdoc/trunk/owl">https://svn.omdoc.org/repos/omdoc/trunk/owl</a> for the corresponding ontology.</p>
	</xd:detail>
	<xd:author>Christoph Lange</xd:author>
	<xd:copyright>Christoph Lange, 2008</xd:copyright>
	<xd:svnId>$Id$</xd:svnId>
    </xd:doc>
    
    <!-- Note that this is not the global default; actually the 
         concrete way of URI generation is decided on element level -->
    <param name="autogenerate-fragment-uris" select="
	'xml-id',
	'document-root-base'"/>

    <!-- Other settings for testing -->
    <!--
    <param name="autogenerate-fragment-uris" select="
	'pseudo-xpath'
	"/>
    -->

    <param name="use-root-xmlid" select="false()"/>

    <include href="util/openmath.xsl"/>

    <template match="node()" mode="krextor:uri-generation-method">
	<param name="mmt" tunnel="yes"/>
        <sequence select="if ($mmt and @name)
	    then ('mmt', $autogenerate-fragment-uris)
	    else $autogenerate-fragment-uris"/>
    </template>
	
    <xd:doc>“Overridden” OMDoc-specific variant of <i>krextor:create-resource</i>, keeps track of a few OMDoc structures and notions that affect many OMDoc elements
	<xd:param name="formality-degree" type="string">the URI of a formality degree from the ontology</xd:param>
	<xd:param name="document-base">the URI of the current document section resource *tunneled)</xd:param>
	<xd:param name="knowledge-base">the URI of the current mathematical or rhetorical structure (tunneled)</xd:param>
	<xd:param name="ontologies" type="string*">a list of values from ('document', 'knowledge'), specifying whether a document section or a mathematical/rhetorical structure resource should be generated from this element</xd:param>
    </xd:doc>
    <template name="krextor:create-omdoc-resource">
	<param name="type"/>
	<param name="formality-degree"/>
	<param name="subject-uri" as="xs:anyURI" tunnel="yes"/>
	<param name="document-base" tunnel="yes"/>
	<param name="knowledge-base" tunnel="yes"/>
	 <!-- <param name="ontologies" required="yes"/> -->
	<param name="ontologies" required="no"/>
	<param name="mmt" tunnel="yes"/>
	<!-- TODO does this work?  In generic.xsl we use
	     instance of document-node() -->
	<param name="use-document-uri" select="not($use-root-xmlid) and self::node() = /"/>
	<param name="process-next" select="*|@*"/>
	<param name="blank-node" select="false()"/>
	<!-- Check if we can at all generate a URI for the current element -->
	<if test="($mmt and @name) or $use-document-uri or @xml:id">
	    <call-template name="krextor:create-resource">
		<with-param name="mmt" select="$mmt" tunnel="yes"/>
		<with-param name="properties">
		    <if test="$formality-degree">
			<krextor:property uri="&odo;formalityDegree" object="{$formality-degree}"/>
		    </if>
		</with-param>
		<with-param name="type" select="$type"/>
		<with-param name="blank-node" select="$blank-node"/>
		<with-param name="process-next" select="$process-next"/>
	    </call-template>
	</if>
    </template>

    <xd:doc>Transforms e.g. false-conjecture → FalseConjecture</xd:doc>
    <function name="omdoc:capitalize-type">
	<param name="type"/>
	<variable name="capitalized-tokens">
	    <for-each select="tokenize($type, '-')">
		<analyze-string select="." regex="^(.)">
		    <matching-substring>
			<value-of select="upper-case(regex-group(1))"/>
		    </matching-substring>
		    <non-matching-substring>
			<value-of select="."/>
		    </non-matching-substring>
		</analyze-string>
	    </for-each>
	</variable>
	<value-of select="string-join($capitalized-tokens, '')"/>
    </function>

    <!-- TODO: There can also be @for for the rhetorical types but it's not yet completely clear where
    the @for should point to and how to model it in the ontology. -->

    <xd:doc>Some SALT rhetorical block types (usable everywhere)</xd:doc>
    <variable name="salt-rhetorical-block-types" select="
	'introduction',
	'background',
	'motivation',
	'scenario',
	'contribution',
	'evaluation',
	'results',
	'discussion',
	'conclusion'"/>

    <xd:doc>All SALT rhetorical block types (usable only on top level)</xd:doc>
    <variable name="salt-rhetorical-block-types-all" select="
	$salt-rhetorical-block-types,
	'abstract',
	'entities'"/>

    <xd:doc>SALT RST-like rhetorical relation types</xd:doc>
    <variable name="salt-rhetorical-relation-types" select="
	'antithesis',
	'circumstance',
	'concession',
	'condition',
	'evidence',
	'means',
	'preparation',
	'purpose',
	'cause',
	'consequence',
	'elaboration',
	'restatement',
	'solutionhood'
	"/>

    <xd:doc>OMDoc assertion types</xd:doc>
    <variable name="omdoc-assertion-types" select="
	'theorem',
	'lemma',
	'corollary',
	'proposition',
	'conjecture',
	'false-conjecture',
	'obligation',
	'postulate',
	'formula',
	'assumption',
	'rule'
	"/>

    <xd:doc>OMDoc statement and assertion types</xd:doc>
    <variable name="omdoc-statement-types" select="
	$omdoc-assertion-types,
	'axiom',
	'definition',
	'example',
	'proof',
	'assertion',
	'rule',
	'hypothesis'
	(: TODO: notation :)
	"/>

    <template match="omdoc:*/@theory" mode="krextor:main">
	<call-template name="krextor:add-uri-property">
	    <with-param name="property" select="'&odo;theoryOf'"/>
	</call-template>
    </template>

    <template match="omdoc" mode="krextor:main">
	<call-template name="krextor:create-omdoc-resource">
	    <with-param name="mmt" select="@version eq '1.6'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;Document'"/>
	    <with-param name="ontologies" select="'document'"/>
	</call-template>
    </template>

    <!--Do we actually need a separate class for tgroup?-->
    <template match="omgroup|tgroup" mode="krextor:main">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, rhetoricalBlock? -->
	    <with-param name="type" select="
		if (@type = $salt-rhetorical-block-types-all) then concat('&sr;', omdoc:capitalize-type(@type))
		else '&odo;DocumentUnit'"/>
	    <with-param name="related-via-properties" select="if (self::tgroup and parent::theory) then '&odo;homeTheoryOf' else '' , if(parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	</call-template>
    </template>

    <template match="ref" mode="krextor:main">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit -->
	    <with-param name="type" select="'&odo;Reference'"/>
	    <with-param name="related-via-properties" select="'&odo;hasPart'" tunnel="yes"/>
	</call-template>
    </template>

    <template match="ref/@xref" mode="krextor:main">
	<call-template name="krextor:add-uri-property">
	    <with-param name="property" select="'&odo;hasReference'"/>
	</call-template>
    </template>


    <template match="theory" mode="krextor:main">	
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock -->
	    <with-param name="related-via-properties" select="if (parent::theory) then '&odo;homeTheoryOf' else '&odo;hasPart' , if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;Theory'"/>
	</call-template>
	<!-- TODO make this the home theory of any statement-level child
	and any subtheory, which is not in an XIncluded or ref-included document
	Probably use a separate mode for that, to be able to match e.g.
	match="definition" mode="child" and generate containsDefinition from that,
	instead of a generic contains relationship. -->
    </template>

    <template match="theory/@meta" mode="krextor:main">
	<call-template name="krextor:add-uri-property">
	    <with-param name="property" select="'&odo;metaTheory'"/>
	</call-template>
    </template>

    <xd:doc>A plain OMDoc 1.2 import without morphism</xd:doc>
    <template match="imports[not(*)]" mode="krextor:main">
	<call-template name="krextor:add-uri-property">
	    <with-param name="property" select="'&odo;imports'"/>
	    <with-param name="object" select="@from"/>
	</call-template>
    </template>

    <xd:doc>An MMT (OMDoc 1.6) import</xd:doc>
    <template match="import" mode="krextor:main">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME mathematicalBlock. Is it a document unit? -->
	    <with-param name="type" select="'&odo;Import'"/>
		<with-param name="related-via-properties" select="if (parent::theory) then '&odo;homeTheoryOf' else '&odo;hasImport' , if (parent::tgroup) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	</call-template>
    </template>    

    <template match="imports/@from" mode="krextor:main">
	<call-template name="krextor:add-uri-property">
	    <with-param name="property" select="'&odo;imports'"/>
	</call-template>
    </template>
	
	
    <template match="omtext/@verbalizes" mode="krextor:main">
	<call-template name="krextor:add-uri-property">
	    <with-param name="object-is-list" select="true()"/>
	    <with-param name="property" select="'&odo;verbalizes'"/>
	</call-template>
    </template>

    <template match="FMP/@logic" mode="krextor:main">
	<call-template name="krextor:add-literal-property">
	    <with-param name="property" select="'&odo;logic'"/>
	</call-template>
    </template>

    <template match="CMP/@xml:lang" mode="krextor:main">
	<call-template name="krextor:add-literal-property">
	    <with-param name="property" select="'&dc;language'"/>
	</call-template>
    </template>

    <template match="om:OMOBJ//om:OMS" mode="krextor:main">
	<call-template name="krextor:add-uri-property">
	    <with-param name="property" select="'&odo;usesSymbol'"/>
	    <!-- use the innermost cdbase attribute. At least the OMOBJ must have a cdbase attribute,
	    or otherwise the default is assumed -->
	    <with-param name="object" select="om:symbol-uri((ancestor-or-self::om:*/@cdbase)[last()], @cd, @name)"/>
	</call-template>
    </template>

    <!-- TODO: MMT imports: add Theory-hasImport-Import-importsFrom-Theory -->

    <!-- TODO adapt to further progress of the MMT (OMDoc 1.6) specification -->
    <template match="symbol[not(@role)]" mode="krextor:main">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME mathematicalBlock. Is it a document unit? -->
		<with-param name="related-via-properties" select="if (parent::proof) then '&odo;hasStep' else if (parent::theory) then '&odo;homeTheoryOf' else '&odo;hasPart' , if (parent::tgroup) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="if (parent::proof)
then '&odo;ProofLocalSymbol'
else '&odo;Symbol'"/>
		<with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template>

    <!-- TODO adapt to further progress of the MMT (OMDoc 1.6) specification -->
    <template match="symbol[@role='axiom']|axiom" mode="krextor:main">
	<!-- axiom/@for missing -->
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock (can contain CMPs) -->
		<with-param name="related-via-properties" select="if (parent::proof) then '&odo;hasStep' else if (parent::theory) then '&odo;homeTheoryOf' else '&odo;hasPart' , if (parent::tgroup) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;Axiom'"/>
	    <with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template>

    <template match="definition[@name or @xml:id]" mode="krextor:main">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock -->
		<with-param name="related-via-properties" select="if (parent::proof) then '&odo;hasStep' else if (parent::theory) then '&odo;homeTheoryOf' else '&odo;hasPart' , if (parent::tgroup) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="if (parent::proof)
then '&odo;ProofLocalDefinition'
else '&odo;Definition'"/>
		<with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template>

    <template match="definition/@for|omtext[@type='definition']/@for" mode="krextor:main">
	<!-- TODO MMT URIs not yet supported; fix this together with the
	improved URI generation, https://trac.kwarc.info/krextor/ticket/16 -->
	<variable name="symbol-uris" as="xs:string*" select="for $id in
	    ancestor::theory//symbol[@name = tokenize(current(), '\s+')]/@xml:id
	    return concat('#', $id)"/> 
	<call-template name="krextor:add-uri-property">
	    <with-param name="property" select="'&odo;defines'"/>
	    <with-param name="object" select="$symbol-uris"/>
	    <with-param name="object-is-list" select="true()"/>
	</call-template>
    </template>

    <template match="example/@for|omtext[@type='example']/@for" mode="krextor:main">
	<call-template name="krextor:add-uri-property">
	    <with-param name="property" select="'&odo;exemplifies'"/>
	</call-template>
    </template>
	

    <template match="alternative" mode="krextor:main">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock -->
		<with-param name="related-via-properties" select="if (parent::theory) then '&odo;homeTheoryOf' else '&odo;hasPart' , if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;AlternativeDefinition'"/>
		<with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template>

    <template match="type[not(parent::symbol)]" mode="krextor:main">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock -->
		<with-param name="related-via-properties" select="if (parent::theory) then '&odo;homeTheoryOf' else '&odo;hasPart' , if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;TypeAssertion'"/>
		<with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template>

    <template match="assertion" mode="krextor:main">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock -->
		<with-param name="related-via-properties" select="if (parent::theory) then '&odo;homeTheoryOf' else '&odo;hasPart' , if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="concat('&odo;',
		if (@type eq 'assumption') then 'AssumptionAssertion'
                else if (@type = $omdoc-assertion-types) then omdoc:capitalize-type(@type)
		else 'Assertion')"/>
	    <with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template>

    <template match="example" mode="krextor:main">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock -->
		<with-param name="related-via-properties" select="if (parent::theory) then '&odo;homeTheoryOf' else '&odo;hasPart' , if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;Example'"/>
		<with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template>

    <template match="proof" mode="krextor:main">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock -->
	    <with-param name="related-via-properties" select="if (parent::method[parent::derive]) then '&odo;justifiedBy' else if (parent::theory) then '&odo;homeTheoryOf' else  '&odo;hasPart' , if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;Proof'"/>
	    <with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template>

    <template match="proofobject" mode="krextor:main">
	<call-template name="krextor:create-omdoc-resource">
	    <with-param name="related-via-properties" select="if (parent::method[parent::derive]) then '&odo;justifiedBy' else if (parent::theory) then '&odo;homeTheoryOf' else  '&odo;hasPart' , if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;Proof'"/>
	    <with-param name="formality-degree" select="'&odo;Computerized'"/>
	</call-template>
    </template>

    <template match="proof/@for|omtext[@type='proof']/@for" mode="krextor:main">
	<call-template name="krextor:add-uri-property">
	    <with-param name="property" select="'&odo;proves'"/>
	</call-template>
    </template>

    <!--TODO omtext/@type='assumption' may have the inductive attribute-->
    <template match="omtext" mode="krextor:main">
    	<variable name="has-mathematical-type" select="@type = $omdoc-statement-types"/>"
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, (mathematicalBlock|rhetoricalBlock)?
	    maybe split into multiple templates -->
	    <with-param name="related-via-properties" select="if (parent::theory and $has-mathematical-type) then '&odo;homeTheoryOf'
	    	else if (parent::proof) then '&odo;hasStep' else '&odo;hasPart' ,
	    	if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="
		if ($has-mathematical-type) then concat('&odo;', omdoc:capitalize-type(@type))
		else if (@type = $salt-rhetorical-block-types) then concat('&sr;', omdoc:capitalize-type(@type))
		else if (@type eq 'derive') then '&odo;DerivationStep'
		else if (parent::proof) then '&odo;ProofText'
		else '&odo;Statement'"/>
	    <with-param name="formality-degree" select="'&odo;Informal'"/>
	</call-template>
    </template>

    <template match="CMP|FMP" mode="krextor:main">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock -->
	    <with-param name="related-via-properties" select="'&odo;hasProperty' , '&sdoc;hasInformationChunk'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;Property'"/>
	    <with-param name="formality-degree" select="if (self::CMP) then '&odo;Informal' else '&odo;Formal'"/>
	</call-template>
    </template>

    <template match="FMP/assumption|omtext[@type='assumption']/@for" mode="krextor:main">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME mathematicalBlock -->
	    <with-param name="related-via-properties" select="'&odo;assumes'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;Assumption'"/>
	</call-template>
    </template>

    <template match="FMP/conclusion" mode="krextor:main">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME mathematicalBlock -->
	    <with-param name="related-via-properties" select="'&odo;concludes'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;Conclusion'"/>
	</call-template>
    </template>

    <template match="CMP//term[@role='definiendum']" mode="krextor:main">
	<call-template name="krextor:add-uri-property">
	    <with-param name="property" select="'&odo;defines'"/>
	    <with-param name="object" select="om:symbol-uri((ancestor-or-self::om:*/@cdbase)[last()], @cd, @name)"/>
	</call-template>
    </template>

    <template match="CMP//term[@role='definiens']" mode="krextor:main">
	<call-template name="krextor:add-uri-property">
	    <with-param name="property" select="'&odo;usesSymbol'"/>
	    <with-param name="object" select="om:symbol-uri((ancestor-or-self::om:*/@cdbase)[last()], @cd, @name)"/>
	</call-template>
    </template>

    <template match="phrase[@type eq 'nucleus']" mode="krextor:main">
	<!-- Here, we just create the resource.
	As it can be used in multiple rhetorical relations, we do that in a second pass -->
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME rhetoricalBlock.  No documentUnit, as below InformationChunk level -->
	    <with-param name="type" select="'&sr;Nucleus'"/>
	</call-template>
    </template>

    <template match="phrase[@type eq 'nucleus']" mode="second-pass">
	<param name="_omdoc-second-pass" tunnel="yes"/>
	<call-template name="krextor:create-omdoc-resource">
	    <!-- Here, we do not actually create the resource but abuse that
	    template to create an additional link from the rhetorical relation
	    to it. -->
	    <with-param name="related-via-properties" select="'&odo;hasNucleus'" tunnel="yes"/>
	</call-template>
    </template>

    <template match="phrase[@type eq 'satellite']" mode="second-pass">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME rhetoricalBlock.  No documentUnit, as below InformationChunk level -->
	    <with-param name="related-via-properties" select="'&odo;hasSatellite'" tunnel="yes"/>
	    <with-param name="type" select="'&sr;Satellite'"/>
	</call-template>
    </template>

    <template match="phrase[@type eq 'satellite']/@for" mode="second-pass">
	<apply-templates select="document(.)" mode="second-pass"/>
    </template>

    <!-- We start processing phrases and rhetorical relations here -->
    <template match="phrase[@type eq 'satellite']" mode="krextor:main">
	<param name="_omdoc-second-pass" tunnel="yes"/>
	<choose>
	    <when test="$_omdoc-second-pass">
		<apply-templates select=".|@for" mode="second-pass">
		    <with-param name="_omdoc-second-pass" select="false()" tunnel="yes"/>
		</apply-templates>
	    </when>
	    <otherwise>
		<call-template name="krextor:create-omdoc-resource">
		    <!-- FIXME rhetoricalBlock.  No documentUnit, as below InformationChunk level -->
		    <with-param name="related-via-inverse-properties" select="'&sr;partOfRhetoricalStructure'" tunnel="yes"/>
		    <with-param name="type" select="concat('&sr;',
			if (@relation = $salt-rhetorical-relation-types) then omdoc:capitalize-type(@relation)
			else 'RhetoricalRelation')"/>
		    <with-param name="blank-node" select="true()"/>
		    <with-param name="process-next" select="."/>
		    <with-param name="_omdoc-second-pass" select="true()" tunnel="yes"/>
		</call-template>
	    </otherwise>
	</choose>
    </template>

    <template match="derive/method/premise" mode="krextor:main">
	<!-- TODO @rank -->
	<!-- enforce the following template to be called -->
	<apply-templates select="@xref" mode="#current"/>
    </template>

    <template match="derive/method/premise/@xref" mode="krextor:main">
	<call-template name="krextor:add-uri-property">
	    <with-param name="property" select="'&odo;justifiedBy'"/>
	    <!--<with-param name="formality-degree" select="'&odo;Informal'"/>-->
	</call-template>
    </template>

    <template match="derive[@type='conclusion']" mode="krextor:main">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock -->
	    <with-param name="related-via-properties" select="'&odo;hasStep' , '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;DerivedConclusion'"/>
	    <with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template>

    <template match="derive[@type='gap']" mode="krextor:main">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock -->
	    <with-param name="related-via-properties" select="'&odo;hasStep' , '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;Gap'"/>
	    <with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template>

    <template match="derive[not(@type='conclusion') and not(@type='gap')]" mode="krextor:main">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock -->
	    <with-param name="related-via-properties" select="'&odo;hasStep' , '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;DerivationStep'"/>
	    <with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template> 

    <template match="hypothesis" mode="krextor:main">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock -->
	    <with-param name="related-via-properties" select="'&odo;hasStep' , '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;Hypothesis'"/>
	    <with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template>

</stylesheet>
