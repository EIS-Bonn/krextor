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
    <!ENTITY owl  "http://www.w3.org/2002/07/owl#">
    <!ENTITY rdfs "http://www.w3.org/2000/01/rdf-schema#">
    <!ENTITY rdf  "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <!ENTITY xsd  "http://www.w3.org/2001/XMLSchema#" >
    <!ENTITY odo  "http://www.omdoc.org/ontology#">
]>

<stylesheet
    xpath-default-namespace="http://omdoc.org/ns"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    xmlns:krextor-genuri="http://kwarc.info/projects/krextor/genuri"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:om="http://www.openmath.org/OpenMath"
    xmlns:odo="http://www.omdoc.org/ontology#"
    xmlns:omdoc="http://omdoc.org/ns"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:f="http://fxsl.sf.net/"
    xmlns="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="#all"
    version="2.0">

    <import href="util/omdoc.xsl"/>

    <xd:doc type="stylesheet">
	Extracts <a href="http://www.w3.org/2004/OWL/">OWL</a> ontologies from <a href="http://www.omdoc.org">OMDoc</a> documents by giving them a special interpretation
	<xd:author>Christoph Lange</xd:author>
	<xd:copyright>Christoph Lange, 2008</xd:copyright>
	<xd:svnId>$Id$</xd:svnId>
    </xd:doc>

    <strip-space elements="*"/>

    <param name="debug" select="true()"/>

    <param name="autogenerate-fragment-uris" select="()"/>

    <function name="krextor:ontology-uri" as="xs:string?">
	<param name="base-uri"/>
	<param name="name"/>
	<sequence select="concat($base-uri, $name)"/>
    </function>

    <template match="krextor-genuri:ontology" as="xs:string?">
	<param name="base-uri"/>
	<param name="node"/>
	<sequence select="krextor:ontology-uri($base-uri, $node/@name)"/>
    </template>

    <function name="krextor:mmt-uri" as="xs:string?">
	<param name="base-uri"/>
	<param name="name"/>
	<sequence select="concat($base-uri, '?', $name)"/>
    </function>

    <template match="krextor-genuri:mmt" as="xs:string?">
	<param name="base-uri"/>
	<param name="node"/>
	<sequence select="krextor:mmt-uri($base-uri, $node/@name)"/>
    </template>

    <template name="krextor:create-ontology-resource">
	<param name="mmt" tunnel="yes"/>
	<param name="type" select="()"/>
	<call-template name="krextor:create-resource">
	    <with-param name="autogenerate-fragment-uri" select="if ($mmt)
		then ('mmt')
		else ('ontology')"/>
	    <with-param name="mmt" select="$mmt" tunnel="yes"/>
	    <with-param name="type" select="$type"/>
	</call-template>
    </template>

    <xd:doc type="element*">A sequence of mappings of CDs representing semantic web ontologies to their corresponding namespaces</xd:doc>
    <variable name="ontology-namespaces">
	<!-- TODO do this on the ref-normal form of the document (cf. $all in exincl.xsl -->
	<for-each select="/descendant::theory">
	    <!-- We collect the set of distinct symbols in this theory, not regarding nested theories -->
	    <variable name="cdus" as="node()*">
		<for-each-group select="descendant::om:OMS[ancestor::theory[1] is current() and not(ancestor::notation)]/@cd" group-by=".">
		    <sequence select="."/>
		</for-each-group>
	    </variable>
	    <!-- we determine those symbols whose symbol definition is not in this document -->
	    <variable name="todo" select="$cdus[not(. = /descendant::theory/@xml:id)]"/>

	    <variable name="catalogue">
		<!-- we search the import graph, starting with our theory. -->
		<call-template name="krextor:make-catalogue">
		    <with-param name="todo" select="$todo"/>
		    <with-param name="theory" select="."/>
		</call-template>
	    </variable>

	    <apply-templates select="$catalogue" mode="krextor:post-process-catalogue">
		<with-param name="this-theory" select="@xml:id" tunnel="yes"/>
	    </apply-templates>
	</for-each>
    </variable>

    <template match="/" mode="krextor:post-process-catalogue">
	<param name="this-theory" tunnel="yes"/>
	<krextor:loc theory="{$this-theory}" omdoc="{concat('#', $this-theory)}">
	    <variable name="sem-web-base" select="krextor:sem-web-base[not(preceding-sibling::*)]"/>
	    <if test="$sem-web-base">
		<attribute name="sem-web-base" select="$sem-web-base"/>
	    </if>
	</krextor:loc>
	<apply-templates select="* except krextor:sem-web-base[not(preceding-sibling::*)]" mode="#current"/>
    </template>

    <template match="krextor:loc" mode="krextor:post-process-catalogue">
	<variable name="sem-web-base" as="xs:string">
	    <variable name="sem-web-base" select="following-sibling::krextor:sem-web-base[@omdoc eq current()/@omdoc]"/>
	    <value-of select="if ($sem-web-base)
		then $sem-web-base
		else if (not(following-sibling::krextor:visited[. eq current()/@omdoc]))
		then krextor:sem-web-base(document(@omdoc))
		else ''"/>
	</variable>
	<if test="$sem-web-base">
	    <copy>
		<copy-of select="@*"/>
		<attribute name="sem-web-base" select="$sem-web-base"/>
	    </copy>
	</if>
    </template>

    <template match="krextor:visited|krextor:sem-web-base" mode="krextor:post-process-catalogue"/>

    <xd:doc>Recursively examine the locally imported theories and locate all theories that still need a catalogue entry.  Each theory is only visited once.  Returns a set of <code>krextor:loc</code> elements.
	<xd:param name="todo">the theories that still need a catalogue entry</xd:param>
	<xd:param name="theory">the theory that is searched for them</xd:param>
	<xd:param name="base-uri">the base URI of the current theory, against which links to imported theories are resolved</xd:param>
	<xd:param name="visited">a set of theories already visited</xd:param>
	<xd:param name="top-level-call" type="boolean">indicates whether this is a top-level or a recursive call</xd:param>
    </xd:doc>
    <template name="krextor:make-catalogue">
	<param name="todo" as="node()*"/>
	<param name="theory" as="node()*"/>
	<param name="base-uri"/>
	<param name="visited" as="node()*" select="()"/>
	<param name="top-level-call" select="true()"/>
	
	<variable name="sem-web-base" select="krextor:sem-web-base($theory)"/>
	<if test="$sem-web-base ne ''">
	    <krextor:sem-web-base omdoc="{concat(base-uri($theory), '#', $theory/@xml:id)}"><value-of select="$sem-web-base"/></krextor:sem-web-base>
	</if>

	<!-- We build the local catalogue and put it in  a variable -->
	<variable name="local-cat">
	    <!-- search for imports in this theory.
	    TODO Are we considering nested theories?  If so, we'd need to
	    search their ancestors as well. -->
	    <for-each select="$theory/imports">
		<krextor:loc
		    theory="{substring-after(@from, '#')}"
		    omdoc="{resolve-uri(@from, $base-uri)}"/>
	    </for-each>
	</variable>

	<!-- those theories that are in the local catalogue of the theory specified by the parameter $theory -->
	<variable name="incat" select="$todo[. = $local-cat/krextor:loc/@theory]"/>

	<!-- ... and those that aren't -->
	<variable name="rest" select="$todo except $incat"/>

	<!-- output loc elements for those theories that are imported from
	other documents and that were searched for (note, this 
	differs from OMDoc's exincl.xsl) -->
	<copy-of select="$local-cat/krextor:loc[@theory = $incat]"/>

	<!-- if there are remaining theories that are not in the local catalogue, recurse to them -->
	<if test="$rest">
	    <variable name="follow" select="$local-cat/krextor:loc[not(@omdoc = $visited)]/@omdoc"/>
	    <!-- there is a catalogue of locally imported, still unvisited theories we can follow -->
	    <if test="$follow">
		<variable name="result">
		    <call-template name="krextor:make-catalogue-iteration">
			<with-param name="todo" select="$rest"/>
			<with-param name="head" select="$follow[1]"/>
			<with-param name="tail" select="$follow[position() gt 1]"/>
			<with-param name="base-uri" select="$base-uri"/>
			<with-param name="visited" select="$visited"/>
			<with-param name="top-level-call" select="$top-level-call"/>
		    </call-template>
		</variable>

		<copy-of select="$result"/>
	    </if>
	</if>
    </template>

    <xd:doc>
	<xd:param name="todo">the theories that still need a catalogue entry</xd:param>
	<xd:param name="head"></xd:param>
	<xd:param name="tail"></xd:param>
	<xd:param name="base-uri">the base URI of the current theory, against which links to imported theories are resolved</xd:param>
	<xd:param name="visited">a set of theories already visited</xd:param>
	<xd:param name="top-level-call" type="boolean">indicates whether this is a top-level or a recursive call</xd:param>
    </xd:doc>
    <template name="krextor:make-catalogue-iteration">
	<param name="todo" as="node()*"/>
	<param name="head" as="node()*"/>
	<param name="tail" as="node()*"/>
	<param name="base-uri"/>
	<param name="visited" as="node()*"/>
	<param name="top-level-call" as="xs:boolean"/>

	<variable name="new-base-uri" select="resolve-uri($head, $base-uri)"/>

	<variable name="recursive-call">
	    <!-- this generates a set of loc's, followed by a list of visited's -->
	    <call-template name="krextor:make-catalogue">
		<with-param name="todo" select="$todo"/>
		<with-param name="theory" select="document($head, .)"/>
		<with-param name="base-uri" select="$new-base-uri"/>
		<with-param name="visited" select="$visited"/>
		<with-param name="top-level-call" select="false()"/>
	    </call-template>
	    <krextor:visited><value-of select="$head"/></krextor:visited>
	</variable>

	<!-- output the output generated by the recursive call
	     (loc, visited, and sem-web-base) -->
	<copy-of select="$recursive-call"/>
	
	<!-- prepare next iteration: search still unvisited theories for imports still not found -->
	<variable name="next-tail" select="$tail[not(. = $recursive-call/krextor:visited)]"/>
	<variable name="next-todo" select="$todo[not(. = $recursive-call/krextor:loc/@theory)]"/>

	<!-- if there are imports to be found ... -->
	<if test="$next-todo">
	    <choose>
		<!-- ... and unvisited theories to search for them ... -->
		<when test="$next-tail">
		    <call-template name="krextor:make-catalogue-iteration">
			<with-param name="todo" select="$next-todo"/>
			<with-param name="head" select="$next-tail[1]"/>
			<with-param name="tail" select="$next-tail[position() gt 1]"/>
			<with-param name="visited" select="$visited|$recursive-call/visited"/>
			<with-param name="base-uri" select="$base-uri"/>
			<with-param name="top-level-call" select="$top-level-call"/>
		    </call-template>
		</when>
		<otherwise>
		    <if test="$top-level-call">
			<message terminate="yes">Cannot find locations for the theories <value-of select="$next-todo" separator=","/>!</message>
		    </if>
		</otherwise>
	    </choose>
	</if>
    </template>

    <xd:doc>Overridden imported function from <code>util/rdfa.xsl</code></xd:doc>
    <function name="krextor:default-curie-namespace">
	<param name="focus"/>
	<value-of select="krextor:default-namespace($focus)"/>
    </function>

    <!-- regular templates matching OMDoc start here -->
    
    <xd:doc>Create a resource from an OMDoc symbol</xd:doc>
    <template match="symbol">
	<call-template name="krextor:create-ontology-resource"/>
    </template>

    <xd:doc>Make this resource an instance of some class</xd:doc>
    <template match="symbol/type[@system='owl']/om:OMOBJ">
	<apply-templates select="om:*[1]">
	    <with-param name="related-via-properties" select="'&rdf;type'" tunnel="yes"/>
	</apply-templates>
    </template>

    <xd:doc>Returns the semantic web URI of a given symbol
	<xd:param name="sym">a symbol that is expected to have <code>@cd</code> and <code>@name</code> attributes (as in OpenMath)</xd:param>
    </xd:doc>
    <function name="krextor:ontology-uri">
	<param name="sym"/>
	<variable name="sem-web-base" select="$ontology-namespaces/krextor:loc[@theory eq $sym/@cd]/@sem-web-base"/>
	<value-of select="if ($sem-web-base)
	    then krextor:ontology-uri($sem-web-base, $sym/@name)
	    else krextor:mmt-uri('MMT-FIXME', concat($sym/@cd, '?', $sym/@name))"/>
    </function>

    <xd:doc>Returns a semantic web URI for the given symbol, if the parameter is a symbol, otherwise the empty sequence.
	<xd:param name="sym">a symbol that is expected to have <code>@cd</code> and <code>@name</code> attributes (as in OpenMath)</xd:param>
    </xd:doc>
    <function name="krextor:ontology-uri-or-blank">
	<param name="sym"/>
	<value-of select="if ($sym/self::om:OMS)
	    then krextor:ontology-uri($sym)
	    else ()"/>
    </function>

    <xd:doc>Creates an RDF triple for a single OWL axiom given as a predicate(subject, object) triple</xd:doc>
    <template match="axiom/FMP[@logic eq 'owl']/om:OMOBJ/om:OMA[count(om:*) eq 3]">
	<variable name="predicate-object-rewritten">
	    <krextor:dummy>
		<om:OMA>
		    <copy-of select="om:*[1]"/><!-- predicate -->
		    <copy-of select="om:*[3]"/><!-- object -->
		</om:OMA>
	    </krextor:dummy>
	</variable>
	<call-template name="krextor:create-resource">
	    <!-- TODO automate this by overriding create-resource -->
	    <with-param name="subject" select="krextor:ontology-uri-or-blank(om:*[2])"/>
	    <with-param name="process-next" select="om:*[2][not(self::om:OMS)]
		|$predicate-object-rewritten/*"/>
	</call-template>
    </template>

    <template match="krextor:dummy/om:OMA[count(om:*) eq 2][om:*[1][self::om:OMS]]">
	<call-template name="krextor:create-resource">
	    <with-param name="related-via-properties" select="krextor:ontology-uri(om:*[1])" tunnel="yes"/>
	    <with-param name="subject" select="krextor:ontology-uri-or-blank(om:*[2])"/>
	    <with-param name="process-next" select="om:*[2][not(self::om:OMS)]"/>
	</call-template>
    </template>

    <xd:doc>Initiates the creation of a class definition</xd:doc>
    <template match="definition[@type eq 'simple']">
	<variable name="symbol" select="document(@for)"/>
	<if test="$symbol">
	    <variable name="symbol-oms">
		<om:OMS cd="{parent::theory/@name}" name="$symbol/@name"/>
	    </variable>
	    <call-template name="krextor:create-resource">
		<with-param name="subject" select="krextor:ontology-uri($symbol)"/>
	    </call-template>
	</if>
    </template>

    <xd:doc>Completes a class definition (via <i>owl:equivalentClass</i>) using
	the definiens</xd:doc>
    <template match="om:OMOBJ[parent::definition[@type eq 'simple']]">
	<choose>
	    <when test="om:*[1][self::om:OMS]">
		<call-template name="krextor:create-resource">
		    <with-param name="related-via-properties" select="'&owl;equivalentClass'" tunnel="yes"/>
		    <with-param name="subject" select="krextor:ontology-uri(om:*[1])"/>
		</call-template>
	    </when>
	    <otherwise>
		<call-template name="krextor:create-resource">
		    <with-param name="blank-node" select="true()"/>
		    <with-param name="process-next" select="om:*[1]"/>
		    <with-param name="related-via-properties" select="'&owl;equivalentClass'" tunnel="yes"/>
		</call-template>
	    </otherwise>
	</choose>
    </template>

    <xd:doc><i>owl:intersectionOf</i> constructor</xd:doc>
    <template match="om:OMA[om:*[1][self::om:OMS[@cd eq 'owl' and @name eq 'intersectionOf']]]">
	<call-template name="krextor:create-resource">
	    <with-param name="related-via-properties" select="'&owl;intersectionOf'" tunnel="yes"/>
	    <with-param name="collection" select="true()"/>
	    <with-param name="process-next" select="om:*[position() ge 2]"/>
	</call-template>
    </template>

    <xd:doc><i>owl:Restriction</i> constructor</xd:doc>
    <template match="om:OMA[count(om:*) eq 3][om:*[1][self::om:OMS[@cd eq 'owl' and @name eq 'Restriction']]][om:*[2][self::om:OMS]]">
	<call-template name="krextor:create-resource">
	    <with-param name="type" select="'&owl;Restriction'"/>
	    <with-param name="properties">
		<krextor:property uri="&owl;onProperty" object="{krextor:ontology-uri(om:*[2])}"/>
	    </with-param>
	    <with-param name="blank-node" select="true()"/>
	    <with-param name="process-next" select="om:*[3]"/>
	</call-template>
    </template>

    <xd:doc>Sets the cardinality of a property restriction</xd:doc>
    <template match="om:OMA[om:*[1][self::om:OMS[@cd eq 'owl' and @name = ('minCardinality', 'maxCardinality', 'cardinality')]]][om:*[2][self::om:OMI]]">
	<call-template name="krextor:add-literal-property">
	    <with-param name="property" select="krextor:ontology-uri(om:*[1])"/>
	    <with-param name="object" select="om:*[2]/text()"/>
	    <with-param name="object-datatype" select="'&xsd;nonNegativeInteger'"/>
	</call-template>
    </template>

    <xd:doc>Creates a resource from an individual symbol</xd:doc>
    <template match="om:OMS">
	<call-template name="krextor:create-resource">
	    <with-param name="subject" select="krextor:ontology-uri(.)"/>
	</call-template>
    </template>

    <xd:doc>Try to find the ontology namespace (calls <code>krextor:sem-web-base</code>)</xd:doc>
    <template match="theory">
	<variable name="sem-web-base" select="$ontology-namespaces/krextor:loc[@theory eq current()/@xml:id]/@sem-web-base"/>
	<variable name="type" select="'&owl;Ontology'"/>
	<choose>
	    <when test="exists($sem-web-base)">
		<call-template name="krextor:create-ontology-resource">
		    <with-param name="base-uri" select="$sem-web-base"
			tunnel="yes"/>
		    <with-param name="type" select="$type"/>
		</call-template>
	    </when>
	    <otherwise>
		<call-template name="krextor:create-ontology-resource">
		    <with-param name="mmt" select="true()" tunnel="yes"/>
		    <with-param name="type" select="$type"/>
		</call-template>
	    </otherwise>
	</choose>
    </template>

    <xd:doc>Try to find the ontology namespace of a given theory (special
	metadata field <code>odo:semWebBase</code>)
	<xd:param name="theory" type="node">the theory</xd:param>
    </xd:doc>
    <function name="krextor:sem-web-base" as="xs:string">
	<param name="theory"/>
	<variable name="link" as="node()*">
	    <sequence select="$theory/metadata/link[krextor:curie-to-uri($theory, @rel) eq '&odo;semWebBase']"/>
	</variable>
	<value-of select="if ($link) then $link/@href else ''"/>
    </function>

    <xd:doc>We don't extract top-level metadata, as they do not correspond to
	anything in an ontology.</xd:doc>
    <template match="/omdoc/metadata"/>

    <xd:doc>We don't extract the special annotation of the ontology namespace
	of a theory, as it is for internal use.</xd:doc>
    <template match="link[krextor:curie-to-uri(., @rel) eq '&odo;semWebBase']"/>
</stylesheet>
