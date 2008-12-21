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
    <!ENTITY omo "http://www.openmath.org/ontology#">
    <!ENTITY rdfs "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY dc "http://purl.org/dc/elements/1.1/">
]>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xpath-default-namespace="http://www.openmath.org/OpenMathCD"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    xmlns="http://www.openmath.org/OpenMathCD"
    xmlns:om="http://www.openmath.org/OpenMath"
    xmlns:cd="http://www.openmath.org/OpenMathCD"
    xmlns:ocds="http://www.openmath.org/OpenMathCDS"
    xmlns:ocdg="http://www.openmath.org/OpenMathCDG"
    xmlns:m="http://www.w3.org/1998/Math/MathML"
    xmlns:mcd="http://www.w3.org/ns/mathml-cd"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:xi="http://www.w3.org/2001/XInclude"
    exclude-result-prefixes="#all"
    version="2.0">

    <xd:doc type="stylesheet">
	<xd:short>Extraction module for <a href="http://www.openmath.org">OpenMath</a> content dictionaries (CDs)</xd:short>
	<xd:detail>
	    <p>This stylesheet extracts RDF from <a href="http://www.openmath.org">OpenMath</a> content dictionaries (CDs).  Currently, RDF is only extracted from top-level elements. CDs are assumed to be split into fragments of interest, which are XIncluded by their parents.  This corresponds to the way OpenMath CDs are used in the semantic wiki <a href="http://kwarc.info/projects/swim/">SWiM</a>.</p>
	    <p>Existing metadata vocabularies are reused, as documented in the ontology.</p>
	    <p>See <a href="https://svn.openmath.org/OpenMath3/owl">https://svn.openmath.org/OpenMath3/owl</a> for the corresponding ontology.</p>
	</xd:detail>
	<xd:author>Christoph Lange</xd:author>
	<xd:copyright>Christoph Lange, 2008</xd:copyright>
	<xd:svnId>$Id$</xd:svnId>
    </xd:doc>

    <xsl:include href="util/openmath.xsl"/>

    <xsl:strip-space elements="*"/>
    
    <xd:doc>Easy XML -> RDF mappings</xd:doc>
    <xsl:variable name="krextor:resources">
	<CD type="&omo;ContentDictionary"/>
	<CDDefinition type="&omo;SymbolDefinition"
	    related-via-properties="&omo;containsSymbolDefinition"/>
	<!-- OpenMath 3 transition: no specific types known yet -->
	<description type="&omo;OpenMathConcept"
	    related-via-properties="&omo;hasDirectPart"/>
	<!-- OpenMath 3 transition: no specific types known yet -->
	<discussion type="&omo;OpenMathConcept"
	    related-via-properties="&omo;hasDirectPart"/>
	<Pragmatic type="&omo;PragmaticGuidelines"
	    related-via-properties="&omo;hasPragmaticGuidelines"/>
	<Example type="&omo;Example"
	    related-via-properties="&omo;hasExample"/>
	<!-- OpenMath 3 transition: allow MMLexample here, too -->
	<MMLexample type="&omo;Example"
	    related-via-properties="&omo;hasExample"/>
	<ocdg:CDGroup type="&omo;ContentDictionaryGroup"/>
	<ocds:CDSignatures type="&omo;SignatureDictionary"/>
	<ocds:Signature type="&omo;Signature"
	    related-via-properties="&omo;containsSignature"/>
	<mcd:notations type="&omo;NotationDictionary"/>
    </xsl:variable>

    <xsl:template match="CD|
	CDDefinition|
	description|
	discussion|
	Pragmatic|
	Example|
	MMLexample|
	ocdg:CDGroup|
	ocds:CDSignatures|
	ocds:Signature|
	mcd:notations">
	<xsl:apply-templates select="." mode="krextor:create-resource"/>
    </xsl:template>    

    <xsl:variable name="krextor:literal-properties">
	<!-- TODO reconsider whether dc:identifier actually is the right property
	     See discussion in the OpenMath ontology source -->
	<Name property="&dc;identifier" normalize-space="true"/>
	<CDName property="&dc;identifier" normalize-space="true"/>
	<Description property="&dc;description" normalize-space="true"/>
	<Title property="&dc;title" normalize-space="true"/>
	<CDDate property="&dc;date" normalize-space="true"/>
	<CDComment property="&rdfs;comment" normalize-space="true"/>
	<CDReviewDate property="&omo;reviewDate" normalize-space="true"/>
	<ocds:CDSReviewDate property="&omo;reviewDate" normalize-space="true"/>
	<CDStatus property="&omo;status" normalize-space="true"/>
	<ocds:CDSStatus property="&omo;status" normalize-space="true"/>
	<CDVersion property="&omo;version" normalize-space="true"/>
	<ocdg:CDGroupVersion property="&omo;version" normalize-space="true"/>
	<CDRevision property="&omo;revision" normalize-space="true"/>
	<ocdg:CDGroupRevision property="&omo;revision" normalize-space="true"/>
	<CDURL property="&omo;url" normalize-space="true"/>
	<ocdg:CDGroupURL property="&omo;url" normalize-space="true"/>
	<!--  for now we store this as a literal, as SWiM does not yet support URI properties with external objects -->
	<CDBase property="&omo;base" normalize-space="true"/>
	<Role property="&omo;role" normalize-space="true"/>
    </xsl:variable>

    <xsl:template match="Name|
	CDName|
	Description|
	Title|
	CDDate|
	CDComment|
	CDReviewDate|
	ocds:CDSReviewDate|
	CDStatus|
	ocds:CDSStatus|
	CDVersion|
	ocdg:CDGroupVersion|
	CDRevision|
	ocdg:CDGroupRevision|
	CDURL|
	ocdg:CDGroupURL|
	(: for now we store this as a literal, as SWiM does not yet support URI
	   properties with external objects :)
	CDBase|
	Role">
	<xsl:apply-templates select="." mode="krextor:add-literal-property"/>
    </xsl:template>

    <!-- Special cases -->

    <xsl:template match="property">
	<xsl:call-template name="krextor:create-resource">
	    <xsl:with-param name="related-via-properties" select="'&omo;hasProperty'" tunnel="yes"/>
	    <xsl:with-param name="type" select="'&omo;Property'"/>
	    <!-- FIXME remove when OpenMath 3 is stable, as then we'll always
	    have CMPs and FMPs inside properties, no longer ones that are
	    direct children of CDDefinition -->
	    <xsl:with-param name="inside-property" select="true()" tunnel="yes"/>
	</xsl:call-template>
    </xsl:template>    

    <xsl:template match="CMP">
	<xsl:call-template name="krextor:create-resource">
	    <!-- This is for OpenMath 2 backwards compatibility.  In OpenMath 3, this
		 will only be a child of property. -->
	    <xsl:with-param name="related-via-properties" select="if (parent::CDDefinition) then '&omo;hasCommentedProperty' else '&omo;hasCommentedPart'" tunnel="yes"/>
	    <xsl:with-param name="type" select="'&omo;CommentedProperty'"/>
	</xsl:call-template>
    </xsl:template>    

    <xsl:template match="FMP">
	<xsl:call-template name="krextor:create-resource">
	    <!-- This is for OpenMath 2 backwards compatibility.  In OpenMath 3, this
		 will only be a child of property. -->
	    <xsl:with-param name="related-via-properties" select="if (parent::CDDefinition) then '&omo;hasFormalProperty' else '&omo;hasFormalPart'" tunnel="yes"/>
	    <xsl:with-param name="type" select="'&omo;FormalProperty'"/>
	</xsl:call-template>
    </xsl:template>    

    <xsl:template match="@type[parent::ocds:CDSignatures]">
	<!-- Currently we assume that @cd is a CD name (in fact a relative URI) to be resolved against the base URI. -->
	<xsl:call-template name="krextor:add-uri-property">
	    <xsl:with-param name="property" select="'&omo;typeSystem'"/>
	    <!-- resolve against the @cdbase if that is available.
		 We assume that @cdbase defines the base both for
		 @cd and for @type. -->
	     <xsl:with-param name="object" select="resolve-uri(., om:cdbase-or-default(../@cdbase))"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="@cd[parent::ocds:CDSignatures]">
	<xsl:call-template name="krextor:add-uri-property">
	    <xsl:with-param name="property" select="'&omo;containsSignaturesFor'"/>
	    <!-- resolve against the @cdbase if that is available.
	    We assume that @cdbase defines the base both for
	    @cd and for @type. -->
	    <xsl:with-param name="object" select="resolve-uri(., om:cdbase-or-default(../@cdbase))"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="@name[parent::ocds:Signature[@cd]]">
	<xsl:call-template name="krextor:add-uri-property">
	    <xsl:with-param name="property" select="'&omo;typesSymbol'"/>
	    <!-- In SWiM, a Signature element is assumed to carry @cdbase and @cd attributes, cf. the discussion of 2008/05/10 on the OM3 mailing list -->
	    <xsl:with-param name="object" select="om:symbol-uri((ancestor::*/@cdbase)[last()], ../@cd, .)"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="mcd:notation">
	<xsl:if test="parent::mcd:notations and not(preceding-sibling::mcd:notation)">
	    <xsl:apply-templates select="." mode="krextor:link-notation-to-cd"/>
	</xsl:if>

	<xsl:call-template name="krextor:create-resource">
	    <xsl:with-param name="related-via-properties" select="'&omo;containsNotationDefinition'" tunnel="yes"/>
	    <xsl:with-param name="type" select="'&omo;Notation'"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="mcd:notation" mode="krextor:link-notation-to-cd">
	<!--
	Here we assume that the mcd:notations element itself does not point to
	a cdbase or a cd, that its mcd:notation children don't do it either,
	but that the prototypes do it (implicitly), and that, of course, there
	is a prototype.

	We assume that all prototypes in one notation dictionary point to to
	the same cdbase and cd, therefore we look up these targets from the
	first child.
	-->
	<xsl:variable name="symbol" select="om:matched-symbol(mcd:prototype[1])"/>
	<xsl:call-template name="krextor:add-uri-property">
	    <!-- implicit subject is the notation dictionary -->
	    <xsl:with-param name="property" select="'&omo;containsNotationsFor'"/>
	    <!-- resolve against the @cdbase if that is available -->
	    <xsl:with-param name="object" select="resolve-uri($symbol/@cd, om:cdbase-or-default($symbol/@cdbase))"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="mcd:prototype[not(preceding-sibling::mcd:prototype)]">
	<xsl:variable name="symbol" select="om:matched-symbol(.)"/>
	<xsl:call-template name="krextor:add-uri-property">
	    <!-- the mcd:notation is the subject -->
	    <xsl:with-param name="property" select="'&omo;rendersSymbol'"/>
	    <xsl:with-param name="object" select="om:symbol-uri(om:cdbase-or-default($symbol/@cdbase), $symbol/@cd, $symbol/@name)"/>
	</xsl:call-template>
    </xsl:template>

    <!-- CDUses is not extracted but computed -->

    <!-- TODO for containment within the same file, either consider @xml:id or target of @href -->
	
    <xsl:template match="CDDefinition" mode="krextor:included">
	<xsl:call-template name="krextor:add-uri-property">
	    <xsl:with-param name="property" select="'&omo;containsSymbolDefinition'"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="description" mode="krextor:included">
	<xsl:call-template name="krextor:add-uri-property">
	    <!-- OpenMath 3 transition: no specific type known yet -->
	    <xsl:with-param name="property" select="'&omo;hasDirectPart'"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="discussion" mode="krextor:included">
	<xsl:call-template name="krextor:add-uri-property">
	    <!-- OpenMath 3 transition: no specific type known yet -->
	    <xsl:with-param name="property" select="'&omo;hasDirectPart'"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="property" mode="krextor:included">
	<xsl:call-template name="krextor:add-uri-property">
	    <xsl:with-param name="property" select="'&omo;hasProperty'"/>
	</xsl:call-template>
    </xsl:template>

    <xd:doc>This is for OpenMath 2 backwards compatibility.  In OpenMath 3, this will be a child of property.</xd:doc>
    <xsl:template match="CMP" mode="krextor:included">
	<!-- FIXME remove when OpenMath 3 is stable, as then we'll always
	have CMPs and FMPs inside properties, no longer ones that are
	direct children of CDDefinition -->
	<xsl:param name="inside-property" select="false()" tunnel="yes"/>
	<xsl:call-template name="krextor:add-uri-property">
	    <xsl:with-param name="property" select="if ($inside-property) then '&omo;hasCommentedPart' else '&omo;hasCommentedProperty'"/>
	</xsl:call-template>
    </xsl:template>

    <xd:doc>This is for OpenMath 2 backwards compatibility.  In OpenMath 3, this will be a child of property.</xd:doc>
    <xsl:template match="FMP" mode="krextor:included">
	<!-- FIXME remove when OpenMath 3 is stable, as then we'll always
	have CMPs and FMPs inside properties, no longer ones that are
	direct children of CDDefinition -->
	<xsl:param name="inside-property" select="false()" tunnel="yes"/>
	<xsl:call-template name="krextor:add-uri-property">
	    <xsl:with-param name="property" select="if ($inside-property) then '&omo;hasFormalPart' else '&omo;hasFormalProperty'"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="Pragmatic" mode="krextor:included">
	<xsl:call-template name="krextor:add-uri-property">
	    <xsl:with-param name="property" select="'&omo;hasPragmaticGuidelines'"/>
	</xsl:call-template>
    </xsl:template>

    <!-- OpenMath 3 transition: allow MMLexample here, too -->
    <xsl:template match="MMLexample|Example" mode="krextor:included">
	<xsl:call-template name="krextor:add-uri-property">
	    <xsl:with-param name="property" select="'&omo;hasExample'"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="om:OMOBJ//om:OMS">
	<xsl:call-template name="krextor:add-uri-property">
	    <xsl:with-param name="property" select="'&omo;usesSymbol'"/>
	    <!-- use the innermost cdbase attribute. At least the OMOBJ must have a cdbase attribute,
	         or otherwise the default is assumed -->
	    <xsl:with-param name="object" select="om:symbol-uri((ancestor-or-self::om:*/@cdbase)[last()], @cd, @name)"/>
	</xsl:call-template>
    </xsl:template>
	
    <xsl:template match="ocdg:CDGroupMember">
	<xsl:call-template name="krextor:add-uri-property">
	    <xsl:with-param name="property" select="'&omo;containsContentDictionary'"/>
	    <!-- We ignore the CDVersion for now -->
	    <!-- If the CDURL is given, use it. Otherwise, resolve CDName against the CDGroupURL, as specified in section 4.4.2.2 of the OpenMath 2.0 Specification. -->
	    <xsl:with-param name="object" select="if (ocdg:CDURL) then ocdg:CDURL/text() else resolve-uri(ocdg:CDName/text(), ../ocdg:CDGroupURL)"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="ocds:Signature" mode="krextor:included">
	<xsl:call-template name="krextor:add-uri-property">
	    <xsl:with-param name="property" select="'&omo;containsSignature'"/>
	</xsl:call-template>
    </xsl:template>


    <xsl:template match="mcd:notation" mode="krextor:included">
	<xsl:param name="krextor:parent-element" tunnel="yes"/>

	<!--
	Here, we assume that mcd:notations cannot have children other than
	mcd:notation (which is the case in MathML 3).
	-->
	<xsl:if test="not($krextor:parent-element/preceding-sibling::mcd:notation|
	    $krextor:parent-element/preceding-sibling::xi:include)">
	    <xsl:apply-templates select="." mode="krextor:link-notation-to-cd"/>
	</xsl:if>

	<xsl:call-template name="krextor:add-uri-property">
	    <xsl:with-param name="property" select="'&omo;containsNotationDefinition'"/>
	</xsl:call-template>
    </xsl:template>

    <!-- TODO:
    Classes:
    CDBase
    -->
</xsl:stylesheet>
