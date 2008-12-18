<?xml version="1.0" encoding="UTF-8"?>

<!--
    *  Copyright (C) 2008
    *  Christoph Lange
    *  Gordan Ristovski
    *  Andrei Ioniţă
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
    <!ENTITY odo "http://www.omdoc.org/ontology#">
    <!ENTITY dc "http://purl.org/dc/elements/1.1/">
    <!ENTITY sdoc "http://salt.semanticauthoring.org/onto/abstract-document-ontology#">
    <!ENTITY sr "http://salt.semanticauthoring.org/onto/rhetorical-ontology#">
]>

<!--
	This stylesheet extracts RDF from OMDoc documents.

	See https://svn.omdoc.org/repos/omdoc/trunk/owl for the corresponding ontology.
-->
<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" 
    xpath-default-namespace="http://omdoc.org/ns"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    xmlns:omdoc="http://omdoc.org/ns"
    xmlns:om="http://www.openmath.org/OpenMath"
    exclude-result-prefixes="omdoc om krextor"
    version="2.0">

    <import href="util/omdoc.xsl"/>
    
    <!-- TODO think about a two-pass processing of resources that can have both
         document-wise physical children and mathematical/rhetorical logical children -->

    <!-- Specifies whether MMT-style URLs (OMDoc 1.3) should be generated -->
    <param name="mmt" select="false()"/>

    <!-- Intercept auto-generation of fragment URIs from xml:ids, as this 
         should not always be done for OMDoc -->
    <!-- TODO think about having ('mmt', 'xml-id' ...), i.e. a configuration in
	 the same way as for generic.xsl, with custom handlers for values like
	 'mmt', which generic-templates does not know -->
    <param name="autogenerate-fragment-uris" select="()"/>

    <!-- Default setting if we want fragment URIs to be auto-generated -->
    <param name="autogenerate-fragment-uris-omdoc-default" select="(
	'xml-id',
	'document-root-base')"/>
    <!-- Other settings for testing -->
    <!--
    <param name="autogenerate-fragment-uris-omdoc-default" select="(
	'pseudo-xpath'
	)"/>
    -->

    <param name="use-root-xmlid" select="false()"/>

    <include href="util/openmath.xsl"/>
	
    <template name="krextor:create-omdoc-resource">
	<param name="type"/>
	<param name="formality-degree"/>
	<param name="subject-uri" tunnel="yes"/>
	<!-- the URI of the current document section resource -->
	<param name="document-base" tunnel="yes"/>
	<!-- the URI of the current mathematical or rhetorical structure -->
	<param name="knowledge-base" tunnel="yes"/>
	<!-- a list of values from ('document', 'knowledge'), specifying
	     whether a document section or a mathematical/rhetorical structure
	     resource should be generated from this element -->
	     <!-- <param name="ontologies" required="yes"/> -->
	<param name="ontologies" required="no"/>
	<param name="mmt" select="$mmt and @name"/>
	<param name="use-document-uri" select="not($use-root-xmlid) and self::node() = /"/>
	<param name="process-next" select="*|@*"/>
	<param name="blank-node" select="false()"/>
	<!-- Check if we can generate a URI for the current element -->
	<if test="$mmt or $use-document-uri or @xml:id">
	    <call-template name="krextor:create-resource">
		<!-- If we are not on top level, manipulate the base URI,
		     either in MMT or in OMDoc 1.2 style -->
		<!-- FIXME look into omdoc-owl.xsl for a better way of how to do this -->
		<with-param name="subject-uri" select="if ($mmt and @name)
		    then concat($subject-uri, '/', @name)
		    else $subject-uri" tunnel="yes"/>
		<with-param name="autogenerate-fragment-uri" select="if (not($mmt) and not($use-document-uri))
		    then $autogenerate-fragment-uris-omdoc-default
		    else ()"/>
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

    <!-- Transforms e.g. false-conjecture -> FalseConjecture -->
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
	<variable name="salt-rhetorical-block-types-all" select="
	    $salt-rhetorical-block-types,
	    'abstract',
	    'entities'"/>
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
	
	<template match="omdoc:*/@theory">
		<call-template name="krextor:add-uri-property">
			<with-param name="property" select="'&odo;theoryOf'"/>
		</call-template>
	</template>
	
	<template match="omdoc">
		<call-template name="krextor:create-omdoc-resource">
			<with-param name="type" select="'&odo;Document'"/>
			<with-param name="ontologies" select="'document'"/>
		</call-template>
	</template>
	
	<!--Do we actually need a separate class for tgroup?-->
	<template match="omgroup|tgroup">
	    <call-template name="krextor:create-omdoc-resource">
		<!-- FIXME documentUnit, rhetoricalBlock? -->
		<with-param name="type" select="
			if (@type = $salt-rhetorical-block-types-all) then concat('&sr;', omdoc:capitalize-type(@type))
			else '&odo;DocumentUnit'"/>
		<with-param name="related-via-properties" select="if (self::tgroup and parent::theory) then '&odo;homeTheoryOf' else '' , if(parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    </call-template>
	</template>
	
	<template match="ref">
		<call-template name="krextor:create-omdoc-resource">
		    <!-- FIXME documentUnit -->
			<with-param name="type" select="'&odo;Reference'"/>
			<with-param name="related-via-properties" select="'&odo;hasPart'" tunnel="yes"/>
		</call-template>
	</template>
	
	<template match="ref/@xref">
		<call-template name="krextor:add-uri-property">
			<with-param name="property" select="'&odo;hasReference'"/>
		</call-template>
	</template>

	
	<template match="theory">	
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

    <template match="theory/@meta">
	<call-template name="krextor:add-uri-property">
	    <with-param name="property" select="'&odo;metaTheory'"/>
	</call-template>
    </template>

    <!-- A plain OMDoc 1.2 import without morphism -->
    <template match="imports[not(*)]">
	<call-template name="krextor:add-uri-property">
	    <with-param name="property" select="'&odo;imports'"/>
	    <with-param name="object" select="@from"/>
	</call-template>
    </template>

    <!-- An MMT (OMDoc 1.3) import -->
    <template match="import">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME mathematicalBlock. Is it a document unit? -->
	    <with-param name="type" select="'&odo;Import'"/>
		<with-param name="related-via-properties" select="if (parent::theory) then '&odo;homeTheoryOf' else '&odo;hasImport' , if (parent::tgroup) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	</call-template>
    </template>    

    <template match="imports/@from">
	<call-template name="krextor:add-uri-property">
	    <with-param name="property" select="'&odo;imports'"/>
	</call-template>
    </template>
	
	
    <template match="omtext/@verbalizes">
		<call-template name="krextor:add-uri-property">
			<with-param name="object-is-list" select="true()"/>
			<with-param name="property" select="'&odo;verbalizes'"/>
		</call-template>
	</template>
	
	<template match="FMP/@logic">
		<call-template name="krextor:add-literal-property">
			<with-param name="property" select="'&odo;logic'"/>
		</call-template>
	</template>
	
	<template match="CMP/@xml:lang">
		<call-template name="krextor:add-literal-property">
			<with-param name="property" select="'&dc;language'"/>
		</call-template>
	</template>

	<template match="om:OMOBJ//om:OMS">
		<call-template name="krextor:add-uri-property">
			<with-param name="property" select="'&odo;usesSymbol'"/>
			<!-- use the innermost cdbase attribute. At least the OMOBJ must have a cdbase attribute,
				or otherwise the default is assumed -->
			<with-param name="object" select="om:symbol-uri((ancestor-or-self::om:*/@cdbase)[last()], @cd, @name)"/>
		</call-template>
	</template>

    <!-- TODO: MMT imports: add Theory-hasImport-Import-importsFrom-Theory -->

    <!-- TODO adapt to further progress of the MMT (OMDoc 1.3) specification -->
    <template match="symbol[not(@role)]">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME mathematicalBlock. Is it a document unit? -->
		<with-param name="related-via-properties" select="if (parent::proof) then '&odo;hasStep' else if (parent::theory) then '&odo;homeTheoryOf' else '&odo;hasPart' , if (parent::tgroup) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;Symbol'"/>
		<with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template>

    <!-- TODO adapt to further progress of the MMT (OMDoc 1.3) specification -->
    <template match="symbol[@role='axiom']|axiom">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock (can contain CMPs) -->
		<with-param name="related-via-properties" select="if (parent::proof) then '&odo;hasStep' else if (parent::theory) then '&odo;homeTheoryOf' else '&odo;hasPart' , if (parent::tgroup) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;Axiom'"/>
	    <with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template>

    <template match="definition[@name or @xml:id]">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock -->
		<with-param name="related-via-properties" select="if (parent::proof) then '&odo;hasStep' else if (parent::theory) then '&odo;homeTheoryOf' else '&odo;hasPart' , if (parent::tgroup) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;Definition'"/>
		<with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template>

	<template match="definition/@for|omtext[@type='definition']/@for">
	<call-template name="krextor:add-uri-property">
	    <with-param name="property" select="'&odo;defines'"/>
	</call-template>
	</template>
	
	<template match="example/@for|omtext[@type='example']/@for">
		<call-template name="krextor:add-uri-property">
			<with-param name="property" select="'&odo;exemplifies'"/>
		</call-template>
	</template>
	

    <template match="alternative">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock -->
		<with-param name="related-via-properties" select="if (parent::theory) then '&odo;homeTheoryOf' else '&odo;hasPart' , if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;AlternativeDefinition'"/>
		<with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template>

    <template match="type[not(parent::symbol)]">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock -->
		<with-param name="related-via-properties" select="if (parent::theory) then '&odo;homeTheoryOf' else '&odo;hasPart' , if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;TypeAssertion'"/>
		<with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template>

    <template match="assertion">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock -->
		<with-param name="related-via-properties" select="if (parent::theory) then '&odo;homeTheoryOf' else '&odo;hasPart' , if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="concat('&odo;',
		if (@type = $omdoc-assertion-types) then omdoc:capitalize-type(@type)
		else 'Assertion')"/>
	    <with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template>

    <template match="example">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock -->
		<with-param name="related-via-properties" select="if (parent::theory) then '&odo;homeTheoryOf' else '&odo;hasPart' , if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;Example'"/>
		<with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template>

    <template match="proof">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock -->
		<with-param name="related-via-properties" select="if (parent::method[parent::derive]) then '&odo;justifiedBy' else if (parent::theory) then '&odo;homeTheoryOf' else  '&odo;hasPart' , if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;Proof'"/>
	    <with-param name="formality-degree" select="'&odo;Formal'"/>
	</call-template>
    </template>
	
	<template match="proofobject">
		<call-template name="krextor:create-omdoc-resource">
			<with-param name="related-via-properties" select="if (parent::method[parent::derive]) then '&odo;justifiedBy' else if (parent::theory) then '&odo;homeTheoryOf' else  '&odo;hasPart' , if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'" tunnel="yes"/>
			<with-param name="type" select="'&odo;Proof'"/>
			<with-param name="formality-degree" select="'&odo;Computerized'"/>
		</call-template>
	</template>
    
	<template match="proof/@for|omtext[@type='proof']/@for">
	<call-template name="krextor:add-uri-property">
	   	<with-param name="property" select="'&odo;proves'"/>
	</call-template>
    </template>
	
    <!--TODO omtext/@type='assumption' may have the inductive attribute-->
    <template match="omtext">
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

    <template match="CMP|FMP">
	<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME documentUnit, mathematicalBlock -->
	    <with-param name="related-via-properties" select="'&odo;hasProperty' , '&sdoc;hasInformationChunk'" tunnel="yes"/>
	    <with-param name="type" select="'&odo;Property'"/>
	    <with-param name="formality-degree" select="if (self::CMP) then '&odo;Informal' else '&odo;Formal'"/>
	</call-template>
    </template>
	
	<template match="FMP/assumption|omtext[@type='assumption']/@for">
		<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME mathematicalBlock -->
			<with-param name="related-via-properties" select="'&odo;assumes'" tunnel="yes"/>
			<with-param name="type" select="'&odo;AssumptionElement'"/>
		</call-template>
	</template>
	
	<template match="FMP/conclusion">
		<call-template name="krextor:create-omdoc-resource">
	    <!-- FIXME mathematicalBlock -->
			<with-param name="related-via-properties" select="'&odo;concludes'" tunnel="yes"/>
			<with-param name="type" select="'&odo;ConclusionElement'"/>
		</call-template>
	</template>
	
	<template match="CMP//term[@role='definiendum']">
		<call-template name="krextor:add-uri-property">
			<with-param name="property" select="'&odo;defines'"/>
			<with-param name="object" select="om:symbol-uri((ancestor-or-self::om:*/@cdbase)[last()], @cd, @name)"/>
		</call-template>
	</template>
	
	<template match="CMP//term[@role='definiens']">
		<call-template name="krextor:add-uri-property">
			<with-param name="property" select="'&odo;usesSymbol'"/>
			<with-param name="object" select="om:symbol-uri((ancestor-or-self::om:*/@cdbase)[last()], @cd, @name)"/>
		</call-template>
	</template>
	
        <template match="phrase[@type eq 'nucleus']">
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
        <template match="phrase[@type eq 'satellite']">
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

	<template match="derive/method/premise">
		<!-- TODO @rank -->
		<!-- enforce the following template to be called -->
		<apply-templates select="@xref" mode="#current"/>
	</template>
	
	<template match="derive/method/premise/@xref">
		<call-template name="krextor:add-uri-property">
			<with-param name="property" select="'&odo;justifiedBy'"/>
			<!--<with-param name="formality-degree" select="'&odo;Informal'"/>-->
		</call-template>
	</template>
	
	<template match="derive[@type='conclusion']">
		<call-template name="krextor:create-omdoc-resource">
		    <!-- FIXME documentUnit, mathematicalBlock -->
			<with-param name="related-via-properties" select="'&odo;hasStep' , '&sdoc;hasPart'" tunnel="yes"/>
			<with-param name="type" select="'&odo;DerivedConclusion'"/>
			<with-param name="formality-degree" select="'&odo;Formal'"/>
		</call-template>
	</template>
	
	<template match="derive[@type='gap']">
		<call-template name="krextor:create-omdoc-resource">
		    <!-- FIXME documentUnit, mathematicalBlock -->
			<with-param name="related-via-properties" select="'&odo;hasStep' , '&sdoc;hasPart'" tunnel="yes"/>
			<with-param name="type" select="'&odo;Gap'"/>
			<with-param name="formality-degree" select="'&odo;Formal'"/>
		</call-template>
	</template>
	
	<template match="derive[not(@type='conclusion') and not(@type='gap')]">
		<call-template name="krextor:create-omdoc-resource">
		    <!-- FIXME documentUnit, mathematicalBlock -->
			<with-param name="related-via-properties" select="'&odo;hasStep' , '&sdoc;hasPart'" tunnel="yes"/>
			<with-param name="type" select="'&odo;DerivationStep'"/>
			<with-param name="formality-degree" select="'&odo;Formal'"/>
		</call-template>
	</template> 
	
	<template match="hypothesis">
		<call-template name="krextor:create-omdoc-resource">
		    <!-- FIXME documentUnit, mathematicalBlock -->
			<with-param name="related-via-properties" select="'&odo;hasStep' , '&sdoc;hasPart'" tunnel="yes"/>
			<with-param name="type" select="'&odo;Hypothesis'"/>
			<with-param name="formality-degree" select="'&odo;Formal'"/>
		</call-template>
	</template>
	
</stylesheet>
