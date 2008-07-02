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
    <!ENTITY dc "http://purl.org/dc/elements/1.1/">
]>

<!--
	This stylesheet extracts RDF from OpenMath content dictionaries (CDs).
	Currently, RDF is only extracted from top-level elements. CDs are assumed
	to be split into fragments of interest, which are XIncluded by their parents.

	See https://svn.openmath.org/OpenMath3/owl for the corresponding ontology.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xpath-default-namespace="http://www.openmath.org/OpenMathCD"
    xmlns:om="http://www.openmath.org/OpenMath"
    xmlns:ocd="http://www.openmath.org/OpenMathCD"
    xmlns:ocds="http://www.openmath.org/OpenMathCDS"
    xmlns:ocdg="http://www.openmath.org/OpenMathCDG"
    xmlns:mcd="http://www.w3.org/ns/mathml-cd"
    exclude-result-prefixes="om ocd ocds ocdg mcd"
    version="2.0">

    <xsl:include href="util-openmath-symbols.xsl"/>

    <xsl:template match="CD">
	<xsl:call-template name="create-resource">
	    <xsl:with-param name="type" select="'&omo;ContentDictionary'"/>
	</xsl:call-template>
    </xsl:template>    

    <xsl:template match="ocdg:CDGroup">
	<xsl:call-template name="create-resource">
	    <xsl:with-param name="type" select="'&omo;ContentDictionaryGroup'"/>
	</xsl:call-template>
    </xsl:template>    

    <xsl:template match="CDDefinition">
	<xsl:call-template name="create-resource">
	    <xsl:with-param name="type" select="'&omo;SymbolDefinition'"/>
	</xsl:call-template>
    </xsl:template>    

    <xsl:template match="CMP">
	<xsl:call-template name="create-resource">
	    <xsl:with-param name="type" select="'&omo;CommentedProperty'"/>
	</xsl:call-template>
    </xsl:template>    

    <xsl:template match="FMP">
	<xsl:call-template name="create-resource">
	    <xsl:with-param name="type" select="'&omo;FormalProperty'"/>
	</xsl:call-template>
    </xsl:template>    

    <xsl:template match="Example">
	<xsl:call-template name="create-resource">
	    <xsl:with-param name="type" select="'&omo;Example'"/>
	</xsl:call-template>
    </xsl:template>    

    <xsl:template match="ocds:CDSignatures">
	<xsl:call-template name="create-resource">
	    <xsl:with-param name="type" select="'&omo;SignatureDictionary'"/>
	</xsl:call-template>
    </xsl:template>    

    <xsl:template match="@type[parent::ocds:CDSignatures]">
	<!-- Currently we assume that @cd is a CD name (in fact a relative URI) to be resolved against the base URI. -->
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&omo;typeSystem'"/>
	    <!-- resolve against the @cdbase if that is available.
		 We assume that @cdbase defines the base both for
		 @cd and for @type. -->
	     <xsl:with-param name="object" select="resolve-uri(concat(., '.ocd'), om:cdbase-or-default(../@cdbase))"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="@cd[parent::ocds:CDSignatures]">
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&omo;containsSignaturesFor'"/>
	    <!-- resolve against the @cdbase if that is available.
	    We assume that @cdbase defines the base both for
	    @cd and for @type. -->
	    <xsl:with-param name="object" select="resolve-uri(concat(., '.ocd'), om:cdbase-or-default(../@cdbase))"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="ocds:Signature">
	<xsl:call-template name="create-resource">
	    <xsl:with-param name="type" select="'&omo;Signature'"/>
	</xsl:call-template>
    </xsl:template>    

    <xsl:template match="@name[parent::ocds:Signature[@cd]]">
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&omo;typesSymbol'"/>
	    <!-- In SWiM, a Signature element is assumed to carry @cdbase and @cd attributes, cf. the discussion of 2008/05/10 on the OM3 mailing list -->
	    <xsl:with-param name="object" select="om:symbol-uri((ancestor::*/@cdbase)[last()], ../@cd, .)"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="mcd:notations">
	<xsl:call-template name="create-resource">
	    <xsl:with-param name="type" select="'&omo;NotationDictionary'"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="mcd:notation">
	<xsl:call-template name="create-resource">
	    <xsl:with-param name="type" select="'&omo;Notation'"/>
	</xsl:call-template>
	
	<!-- Here we assume that the mcd:notations element itself does not 
	point to a cdbase or a cd but that only its mcd:notation children do.
	We assume that all mcd:notation children of one mcd:notations point
	to the same cdbase and cd, therefore we look up these targets from the
	first child. -->
	<xsl:if test="parent::mcd:notations and @cd and not(preceding-sibling::mcd:notation)">
	    <xsl:call-template name="add-uri-property">
		<xsl:with-param name="property" select="'&omo;containsNotationsFor'"/>
		<!-- resolve against the @cdbase if that is available -->
		<xsl:with-param name="object" select="resolve-uri(concat(@cd, '.ocd'), om:cdbase-or-default(@cdbase))"/>
		<!-- TODO rewrite this for SWiM -->
	    </xsl:call-template>
	</xsl:if>
    </xsl:template>

    <xsl:template match="@name[parent::mcd:notation[@cd]]">
	<xsl:variable name="notation" select="parent::mcd:notation"/>
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&omo;rendersSymbol'"/>
	    <!-- Here we assume that the mcd:notations element itself does not 
	    point to a cdbase or a cd but that its mcd:notation children 
	    have attributes @cdbase, @cd, and @name -->
	    <!-- resolve against the @cdbase if that is available -->
	    <xsl:with-param name="object" select="om:symbol-uri(om:cdbase-or-default($notation/@cdbase), $notation/@cd, $notation/@name)"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="Name|CDName">
	<!-- TODO reconsider whether dc:identifier actually is the right property -->
	<xsl:call-template name="add-literal-property">
	    <xsl:with-param name="property" select="'&dc;identifier'"/>
	    <xsl:with-param name="normalize-space" select="true()"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="Description">
	<xsl:call-template name="add-literal-property">
	    <xsl:with-param name="property" select="'&dc;description'"/>
	    <xsl:with-param name="normalize-space" select="true()"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="CDDate">
	<xsl:call-template name="add-literal-property">
	    <xsl:with-param name="property" select="'&dc;date'"/>
	    <xsl:with-param name="normalize-space" select="true()"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="CDComment">
	<xsl:call-template name="add-literal-property">
	    <xsl:with-param name="property" select="'&dc;comment'"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="CDReviewDate|ocds:CDSReviewDate">
	<xsl:call-template name="add-literal-property">
	    <xsl:with-param name="property" select="'&omo;reviewDate'"/>
	    <xsl:with-param name="normalize-space" select="true()"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="CDStatus|ocds:CDSStatus">
	<xsl:call-template name="add-literal-property">
	    <xsl:with-param name="property" select="'&omo;status'"/>
	    <xsl:with-param name="normalize-space" select="true()"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="CDVersion|ocdg:CDGroupVersion">
	<xsl:call-template name="add-literal-property">
	    <xsl:with-param name="property" select="'&omo;version'"/>
	    <xsl:with-param name="normalize-space" select="true()"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="CDRevision|ocdg:CDGroupRevision">
	<xsl:call-template name="add-literal-property">
	    <xsl:with-param name="property" select="'&omo;revision'"/>
	    <xsl:with-param name="normalize-space" select="true()"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="CDURL|ocdg:CDGroupURL">
	<xsl:call-template name="add-literal-property">
	    <xsl:with-param name="property" select="'&omo;url'"/>
	    <xsl:with-param name="normalize-space" select="true()"/>
	</xsl:call-template>
    </xsl:template>

    <!-- CDUses is not extracted but computed -->

    <!--  for now we store this as a literal, as SWiM does not yet support URI properties with external objects -->
    <xsl:template match="CDBase">
	<xsl:call-template name="add-literal-property">
	    <xsl:with-param name="property" select="'&omo;base'"/>
	    <xsl:with-param name="normalize-space" select="true()"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="Role">
	<xsl:call-template name="add-literal-property">
	    <xsl:with-param name="property" select="'&omo;role'"/>
	    <xsl:with-param name="normalize-space" select="true()"/>
	</xsl:call-template>
    </xsl:template>
	
    <!-- TODO for containment within the same file, either consider @xml:id or target of @href -->
	
    <xsl:template match="CDDefinition" mode="included">
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&omo;containsSymbolDefinition'"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="CMP" mode="included">
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&omo;hasCommentedProperty'"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="FMP" mode="included">
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&omo;hasFormalProperty'"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="Example" mode="included">
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&omo;hasExample'"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="om:OMOBJ//om:OMS">
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&omo;usesSymbol'"/>
	    <!-- use the innermost cdbase attribute. At least the OMOBJ must have a cdbase attribute,
	         or otherwise the default is assumed -->
	    <xsl:with-param name="object" select="om:symbol-uri((ancestor-or-self::om:*/@cdbase)[last()], @cd, @name)"/>
	</xsl:call-template>
    </xsl:template>
	
    <xsl:template match="ocdg:CDGroupMember">
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&omo;containsContentDictionary'"/>
	    <!-- We ignore the CDVersion for now -->
	    <!-- If the CDURL is given, use it. Otherwise, resolve CDName against the CDGroupURL, as specified in section 4.4.2.2 of the OpenMath 2.0 Specification. -->
	    <xsl:with-param name="object" select="if (ocdg:CDURL) then ocdg:CDURL/text() else resolve-uri(concat(ocdg:CDName/text(), '.ocd'), ../ocdg:CDGroupURL)"/>
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="ocds:Signature" mode="included">
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&omo;containsSignature'"/>
	</xsl:call-template>
    </xsl:template>


    <xsl:template match="mcd:notation" mode="included">
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&omo;containsNotationDefinition'"/>
	</xsl:call-template>
    </xsl:template>

    <!-- TODO:
    Classes:
    CDBase
    -->
</xsl:stylesheet>
