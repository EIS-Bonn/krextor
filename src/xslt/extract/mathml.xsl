<?xml version="1.0" encoding="UTF-8"?>

<!--
    *  Copyright (C) 2012
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
    xmlns:m="http://www.w3.org/1998/Math/MathML"
    xmlns:om="http://www.openmath.org/OpenMath"
    xpath-default-namespace="http://www.w3.org/1998/Math/MathML"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    xmlns:krextor-genuri="http://kwarc.info/projects/krextor/genuri"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    exclude-result-prefixes="#all"
    version="2.0">
    <import href="util/openmath-uris.xsl"/>
    
    <xd:doc>generate all URIs from @id attributes</xd:doc>
    <param name="autogenerate-fragment-uris" select="'id'"/>
    
    <template match="math" mode="krextor:main">
        <choose>
            <when test="@cdgroup">
                <apply-imports>
                    <with-param name="cdgroup" select="document(@cdgroup)" tunnel="yes"/>
                </apply-imports>
            </when>
            <otherwise>
                <apply-imports/>
            </otherwise>
        </choose>
    </template>
    
    <xd:doc>
        <xd:short>create untyped resources from semantics elements</xd:short>
        <xd:detail>Creates an untyped resource from a <code>semantics</code> element.  Types, if any, will be added explicitly via <code>rdf:type</code> properties.</xd:detail>
    </xd:doc>
    <template match="semantics" mode="krextor:main">
        <call-template name="krextor:create-resource"/>
    </template>

    <xd:doc>
        <xd:short>from the attributes of an <code>annotation</code> or <code>annotation-xml</code> elements, determine the annotation property to be used</xd:short>
        <xd:detail>From the attributes of an <code>annotation</code> or <code>annotation-xml</code> elements, determine the annotation property to be used.  The way of doing so is specified in the <a href="http://www.w3.org/TR/MathML3/chapter5.html#mixing.annotation.keys">“annotation keys” section of the MathML specification</a>.</xd:detail>
    </xd:doc>
    <function name="krextor:mathml-annotation-property-uri" as="xs:anyURI">
        <param name="element" as="element()"/>
        <param name="cdgroup"/>

        <variable name="property-as-string">
            <choose>
                <when test="$element/@cd and $element/@name">
                    <!-- In MathML 3, annotation keys are defined as symbols in Content Dictionaries, and are specified using of the cd and name attributes on the annotation and annotation-xml elements. -->
                    <value-of select="om:symbol-uri($cdgroup, $element/@cd, $element/@name)"/>
                    <if test="$element/@definitionURL">
                        <message>both (@cd, @name) and @definitionURL found in <value-of select="local-name($element)"/> element; I will give preference to (@cd, @name) and ignore @definitionURL</message>
                    </if>
                </when>
                <when test="$element/@definitionURL">
                    <!-- For backward compatibility with MathML 2, an annotation key may also be referenced using the definitionURL attribute as an alternative to the cd and name attributes. -->
                    <value-of select="$element/@definitionURL"/>
                </when>
                <otherwise>
                    <!-- The default annotation key is alternate-representation when no annotation key is explicitly specified on an annotation or annotation-xml element. -->
                    <value-of select="om:symbol-uri((), 'mathmlkeys', 'alternate-representation')"/>
                    <if test="$element/@cd">
                        <message>ignoring @cd without @name</message>
                    </if>
                    <if test="$element/@name">
                        <message>ignoring @name without @cd</message>
                    </if>
                </otherwise>
            </choose>
        </variable>
        <value-of select="xs:anyURI($property-as-string)"/>
    </function>
    
    <template match="annotation|annotation-xml" mode="krextor:main">
        <param name="cdgroup" tunnel="yes"/>
        <variable name="property" select="krextor:mathml-annotation-property-uri(., $cdgroup)"/>
        <if test="$property">
            <choose>
                <when test="node() or not(@src)">
                    <if test="node() and @src">
                        <message>both @src and non-empty content found in <value-of select="local-name()"/> element; I will give preference to the content and ignore @src</message>
                    </if>
                    <call-template name="krextor:add-literal-property">
                        <with-param name="property" select="$property"/>
                        <with-param name="language" select="@xml:lang"/>
                        <!-- not sure how we could encode the datatype of a literal in MathML -->
                    </call-template>
                </when>
                <otherwise>
                    <call-template name="krextor:add-uri-property">
                        <with-param name="property" select="$property"/>
                        <with-param name="object" select="@src"/>
                    </call-template>
                </otherwise>
            </choose>
        </if>
    </template>
</stylesheet>

<!--
Local Variables:
mode: nxml
nxml-child-indent: 4
End:
-->

