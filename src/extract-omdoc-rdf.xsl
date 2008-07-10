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

<!DOCTYPE xsl:stylesheet [
    <!ENTITY odo "http://www.omdoc.org/ontology#">
    <!ENTITY dc "http://purl.org/dc/elements/1.1/">
    <!ENTITY sdoc "http://salt.semanticauthoring.org/onto/abstract-document-ontology#">
    <!ENTITY sr "http://salt.semanticauthoring.org/onto/2007/10/rhetorical-ontology.rdfs#">
]>

<!--
	This stylesheet extracts RDF from OMDoc documents.

	See https://svn.omdoc.org/repos/omdoc/trunk/owl for the corresponding ontology.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xpath-default-namespace="http://www.mathweb.org/omdoc"
    xmlns:krextor="http://kwarc.info/projects/krextor/"
    xmlns:omdoc="http://www.mathweb.org/omdoc"
    xmlns:om="http://www.openmath.org/OpenMath"
    exclude-result-prefixes="omdoc om krextor"
    version="2.0">

    <!-- TODO add rhetorical stuff -->
    <!-- TODO group omtext templates together, just capitalise @type -> ontology concepts -->

    <!-- Specifies whether MMT-style URLs (OMDoc 1.3) should be generated -->
    <xsl:param name="mmt" select="false()"/>

    <!-- Intercept auto-generation of fragment URIs from xml:ids, as this 
         should not always be done for OMDoc -->
    <!-- TODO think about having ('mmt', 'xml-id' ...), i.e. a configuration in
         the same way as for generic-templates.xsl, with custom handlers for 
	 values like 'mmt', which generic-templates does not know -->
    <xsl:param name="autogenerate-fragment-uris" select="()"/>

    <!-- Default setting if we want fragment URIs to be auto-generated -->
    <xsl:param name="autogenerate-fragment-uris-omdoc-default" select="(
	'xml-id',
	'document-root-base')"/>
    <!-- Other settings for testing -->
    <!--
    <xsl:param name="autogenerate-fragment-uris-omdoc-default" select="(
	'pseudo-xpath'
	)"/>
    -->

    <xsl:param name="use-root-xmlid" select="false()"/>

    <xsl:include href="util-openmath-symbols.xsl"/>
	
    <xsl:template name="create-omdoc-resource">
	<xsl:param name="type"/>
	<xsl:param name="related-via-properties" select="()"/>
	<xsl:param name="formality-degree"/>
	<xsl:param name="base-uri" tunnel="yes"/>
	<xsl:param name="mmt" select="$mmt and @name"/>
	<xsl:param name="use-document-uri" select="not($use-root-xmlid) and self::node() = /"/>
	<xsl:param name="process-next" select="()"/>
	<xsl:param name="blank-node" select="false()"/>
	<!-- Check if we can generate a URI for the current element -->
	<xsl:if test="$mmt or $use-document-uri or @xml:id">
	    <xsl:call-template name="create-resource">
		<!-- If we are not on top level, manipulate the base URI,
		     either in MMT or in OMDoc 1.2 style -->
		<xsl:with-param name="base-uri" select="if ($mmt and @name)
		    then concat($base-uri, '/', @name)
		    else $base-uri" tunnel="yes"/>
		<xsl:with-param name="autogenerate-fragment-uri" select="if (not($mmt) and not($use-document-uri))
		    then $autogenerate-fragment-uris-omdoc-default
		    else ()"/>
		<xsl:with-param name="properties">
		    <xsl:if test="$formality-degree">
			<krextor:property uri="&odo;formalityDegree" object="{$formality-degree}"/>
		    </xsl:if>
		</xsl:with-param>
		<xsl:with-param name="type" select="$type"/>
		<xsl:with-param name="blank-node" select="$blank-node"/>
		<xsl:with-param name="related-via-properties" select="$related-via-properties"/>
		<xsl:with-param name="process-next" select="$process-next"/>
	    </xsl:call-template>
	</xsl:if>
    </xsl:template>

    <!-- Transforms e.g. false-conjecture -> FalseConjecture -->
    <xsl:function name="omdoc:capitalize-type">
	<xsl:param name="type"/>
	<xsl:variable name="capitalized-tokens">
	    <xsl:for-each select="tokenize($type, '-')">
		<xsl:analyze-string select="." regex="^(.)">
		    <xsl:matching-substring>
			<xsl:value-of select="upper-case(regex-group(1))"/>
		    </xsl:matching-substring>
		    <xsl:non-matching-substring>
			<xsl:value-of select="."/>
		    </xsl:non-matching-substring>
		</xsl:analyze-string>
	    </xsl:for-each>
	</xsl:variable>
	<xsl:value-of select="string-join($capitalized-tokens, '')"/>
    </xsl:function>
	
	<xsl:template match="omdoc">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="type" select="'&odo;Document'"/>
		</xsl:call-template>
	</xsl:template>
	
	<!--Do we actually need a separate class for tgroup?-->
	<xsl:template match="omgroup|tgroup">
	    <xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="type" select="
			if (@type = (
			    (: rhetoric block types (SALT) :)
			    'introduction',
			    'background',
			    'motivation',
			    'scenario',
			    'contribution',
			    'evaluation',
			    'results',
			    'discussion',
			    'conclusion',
                            (: plus the ones that we allow on group level :)
                            'abstract',
                            'entities'
			)) then concat('&sr;', omdoc:capitalize-type(@type))
			else '&odo;DocumentUnit'"/>
		<xsl:with-param name="related-via-properties" select="if(parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'"/>
	    </xsl:call-template>
	</xsl:template>
	
	<xsl:template match="ref">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="type" select="'&odo;Reference'"/>
			<xsl:with-param name="related-via-properties" select="'&odo;hasPart'"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="ref/@xref">
		<xsl:call-template name="add-uri-property">
			<xsl:with-param name="property" select="'&odo;hasReference'"/>
		</xsl:call-template>
	</xsl:template>
		
	<xsl:template match="metadata/*">
		<xsl:call-template name="add-literal-property">
			<xsl:with-param name="property" select="concat(namespace-uri(), local-name())"/>
		</xsl:call-template>
	</xsl:template>

	
	<xsl:template match="theory">	
    		<xsl:call-template name="create-omdoc-resource">
    			<xsl:with-param name="related-via-properties" select="if(parent::omdoc or parent::omgroup) then '&odo;homeTheoryOf' else '&odo;hasPart', if(parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'"/>
	   		<xsl:with-param name="type" select="'&odo;Theory'"/>
		</xsl:call-template>
	<!-- TODO make this the home theory of any statement-level child
	and any subtheory, which is not in an XIncluded or ref-included document
	Probably use a separate mode for that, to be able to match e.g.
	match="definition" mode="child" and generate containsDefinition from that,
	instead of a generic contains relationship. -->
	</xsl:template>

    <xsl:template match="theory/@meta">
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&odo;metaTheory'"/>
	</xsl:call-template>
    </xsl:template>

    <!-- A plain OMDoc 1.2 import without morphism -->
    <xsl:template match="imports[not(*)]">
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&odo;imports'"/>
	    <xsl:with-param name="object" select="@from"/>
	</xsl:call-template>
    </xsl:template>

    <!-- An MMT (OMDoc 1.3) import -->
    <xsl:template match="import">
	<xsl:call-template name="create-omdoc-resource">
	    <xsl:with-param name="type" select="'&odo;Import'"/>
		<xsl:with-param name="related-via-properties" select="if (parent::tgroup) then '&sdoc;hasComposite' else '&sdoc;hasPart'"/>
	</xsl:call-template>
    </xsl:template>    

    <xsl:template match="imports/@from">
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&odo;imports'"/>
	</xsl:call-template>
    </xsl:template>
	
	
    <xsl:template match="omtext/@verbalizes">
		<xsl:call-template name="add-uri-property">
			<xsl:with-param name="list" select="true()"/>
			<xsl:with-param name="property" select="'&odo;verbalizes'"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="FMP/@logic">
		<xsl:call-template name="add-literal-property">
			<xsl:with-param name="property" select="'&odo;logic'"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="CMP/@xml:lang">
		<xsl:call-template name="add-literal-property">
			<xsl:with-param name="property" select="'&dc;language'"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="om:OMOBJ//om:OMS">
		<xsl:call-template name="add-uri-property">
			<xsl:with-param name="property" select="'&odo;usesSymbol'"/>
			<!-- use the innermost cdbase attribute. At least the OMOBJ must have a cdbase attribute,
				or otherwise the default is assumed -->
			<xsl:with-param name="object" select="om:symbol-uri((ancestor-or-self::om:*/@cdbase)[last()], @cd, @name)"/>
		</xsl:call-template>
	</xsl:template>

    <!-- TODO: MMT imports: add Theory-hasImport-Import-importsFrom-Theory -->

    <!-- TODO adapt to further progress of the MMT (OMDoc 1.3) specification -->
    <xsl:template match="symbol[not(@role)]">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-properties" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart' , if (parent::tgroup) then '&sdoc;hasComposite' else '&sdoc;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Symbol'"/>
		<xsl:with-param name="formality-degree" select="'&odo;Formal'"/>
	</xsl:call-template>
    </xsl:template>

    <!-- TODO adapt to further progress of the MMT (OMDoc 1.3) specification -->
    <xsl:template match="symbol[@role='axiom']|axiom">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-properties" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart' , if (parent::tgroup) then '&sdoc;hasComposite' else '&sdoc;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Axiom'"/>
	    <xsl:with-param name="formality-degree" select="'&odo;Formal'"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="definition[@name or @xml:id]">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-properties" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart' , if (parent::tgroup) then '&sdoc;hasComposite' else '&sdoc;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Definition'"/>
		<xsl:with-param name="formality-degree" select="'&odo;Formal'"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="definition/@for">
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&odo;defines'"/>
	</xsl:call-template>
    </xsl:template>
	
	
    <xsl:template match="alternative">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-properties" select="'&odo;hasPart' , if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;AlternativeDefinition'"/>
		<xsl:with-param name="formality-degree" select="'&odo;Formal'"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="type[not(parent::symbol)]">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-properties" select="'&odo;hasPart' , if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;TypeAssertion'"/>
		<xsl:with-param name="formality-degree" select="'&odo;Formal'"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="assertion">
	<xsl:call-template name="create-omdoc-resource">
	    <xsl:with-param name="related-via-properties" select="'&odo;hasPart' , if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'"/>
	    <xsl:with-param name="type" select="concat('&odo;',
		if (@type = (
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
		)) then omdoc:capitalize-type(@type)
		else 'Assertion')"/>
	    <xsl:with-param name="formality-degree" select="'&odo;Formal'"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="example">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-properties" select="'&odo;hasPart' , if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Example'"/>
		<xsl:with-param name="formality-degree" select="'&odo;Formal'"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="proof">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-properties" select="if (parent::method[parent::derive]) then '&odo;justifiedBy' else '&odo;hasPart' , if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Proof'"/>
	    <xsl:with-param name="formality-degree" select="'&odo;Formal'"/>
	</xsl:call-template>
    </xsl:template>
    
    <xsl:template match="proof/@for">
	<xsl:call-template name="add-uri-property">
	   	<xsl:with-param name="property" select="'&odo;proves'"/>
	</xsl:call-template>
    </xsl:template>
	
    <!--TODO omtext/@type='assumption' may have the inductive attribute-->
    <xsl:template match="omtext">
	<xsl:call-template name="create-omdoc-resource">
	    <xsl:with-param name="related-via-properties" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart' , if (parent::omdoc) then '&sdoc;hasComposite' else '&sdoc;hasPart'"/>
	    <xsl:with-param name="type" select="
		if (@type = (
		    (: mathematical types :)
		    'axiom',
		    'definition',
		    'example',
		    'proof',
		    'assertion',
		    'corollary',
		    'conjecture', 
		    'false-conjecture', 
		    'formula', 
		    'lemma', 
		    'postulate', 
		    'proposition', 
		    'theorem', 
		    'assumption', 
		    'obligation', 
		    'rule',
                    'hypothesis'
                    (: TODO: notation :)
		)) then concat('&odo;', omdoc:capitalize-type(@type))
		else if (@type = (
                    (: rhetoric block types (SALT) :)
		    'introduction',
                    'background',
                    'motivation',
                    'scenario',
                    'contribution',
                    'evaluation',
                    'results',
                    'discussion',
                    'conclusion'
                )) then concat('&sr;', omdoc:capitalize-type(@type))
		else if (@type eq 'derive') then '&odo;DerivationStep'
		else if (parent::proof) then '&odo;ProofText'
		else '&odo;Statement'"/>
	    <xsl:with-param name="formality-degree" select="'&odo;Informal'"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="CMP|FMP">
	<xsl:call-template name="create-omdoc-resource">
	    <xsl:with-param name="related-via-properties" select="'&odo;hasProperty' , '&sdoc;hasInformationChunk'"/>
	    <xsl:with-param name="type" select="'&odo;Property'"/>
	    <xsl:with-param name="formality-degree" select="if (self::CMP) then '&odo;Informal' else '&odo;Formal'"/>
	</xsl:call-template>
    </xsl:template>
	
	<xsl:template match="FMP/assumption">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-properties" select="'&odo;assumes'"/>
			<xsl:with-param name="type" select="'&odo;AssumptionElement'"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="FMP/conclusion">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-properties" select="'&odo;concludes'"/>
			<xsl:with-param name="type" select="'&odo;ConclusionElement'"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="CMP//term[@role='definiendum']">
		<xsl:call-template name="add-uri-property">
			<xsl:with-param name="property" select="'&odo;defines'"/>
			<xsl:with-param name="object" select="om:symbol-uri((ancestor-or-self::om:*/@cdbase)[last()], @cd, @name)"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="CMP//term[@role='definiens']">
		<xsl:call-template name="add-uri-property">
			<xsl:with-param name="property" select="'&odo;usesSymbol'"/>
			<xsl:with-param name="object" select="om:symbol-uri((ancestor-or-self::om:*/@cdbase)[last()], @cd, @name)"/>
		</xsl:call-template>
	</xsl:template>
	
        <xsl:template match="phrase[@type eq 'nucleus']" mode="redirected-processing">
	    <xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-properties" select="'&odo;hasNucleus'"/>
		<!-- Note that this triple is created as many times as the
		nucleus participates in rhetoric relations, i.e. as many times
		as it's references from some satellites. --> 
		<xsl:with-param name="type" select="'&sr;Nucleus'"/>
	    </xsl:call-template>
	</xsl:template>

	<xsl:template match="phrase[@type eq 'satellite']" mode="redirected-processing">
	    <xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-properties" select="'&odo;hasSatellite'"/>
		<xsl:with-param name="type" select="'&sr;Satellite'"/>
	    </xsl:call-template>
	</xsl:template>

	<xsl:template match="phrase[@type eq 'satellite']/@for" mode="redirected-processing">
	    <xsl:apply-templates select="document(.)" mode="redirected-processing"/>
	</xsl:template>

        <xsl:template match="phrase[@type eq 'satellite']">
	    <xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-properties" select="'&odo;hasRhetoricRelation'"/>
		<xsl:with-param name="type" select="concat('&sr;',
			if (@relation = (
			    (: rhetoric relation types (SALT) :)
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
			)) then omdoc:capitalize-type(@relation)
			else 'RhetoricRelation')"/>
		<xsl:with-param name="blank-node" select="true()"/>
		<xsl:with-param name="process-next" select=".|@for"/>
	    </xsl:call-template>
	</xsl:template>

	<xsl:template match="derive/method/premise">
		<!-- TODO @rank -->
		<!-- enforce the following template to be called -->
		<xsl:apply-templates select="@xref"/>
	</xsl:template>
	
	<xsl:template match="derive/method/premise/@xref">
		<xsl:call-template name="add-uri-property">
			<xsl:with-param name="property" select="'&odo;justifiedBy'"/>
			<!--<xsl:with-param name="formality-degree" select="'&odo;Informal'"/>-->
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="derive[@type='conclusion']">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-properties" select="'&odo;hasStep' , '&sdoc;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;DerivedConclusion'"/>
			<xsl:with-param name="formality-degree" select="'&odo;Formal'"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="derive[@type='gap']">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-properties" select="'&odo;hasStep' , '&sdoc;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Gap'"/>
			<xsl:with-param name="formality-degree" select="'&odo;Formal'"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="derive[not(@type='conclusion') and not(@type='gap')]">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-properties" select="'&odo;hasStep' , '&sdoc;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;DerivationStep'"/>
			<xsl:with-param name="formality-degree" select="'&odo;Formal'"/>
		</xsl:call-template>
	</xsl:template> 
	
	<xsl:template match="hypothesis">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-properties" select="'&odo;hasStep' , '&sdoc;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Hypothesis'"/>
			<xsl:with-param name="formality-degree" select="'&odo;Formal'"/>
		</xsl:call-template>
	</xsl:template>
	
</xsl:stylesheet>
