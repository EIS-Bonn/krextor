<!DOCTYPE stylesheet  [
<!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
<!ENTITY rdfs "http://www.w3.org/2000/01/rdf-schema#">
<!ENTITY dc "http://purl.org/dc/elements/1.1/">
<!ENTITY aml "https://w3id.org/i40/aml/">
<!ENTITY xsd "http://www.w3.org/2001/XMLSchema#">
<!ENTITY schema "http://schema.org/">
]>




<xsl:transform version="2.0" 
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xmlns:krextor="http://kwarc.info/projects/krextor"
               xmlns:krextor-genuri="http://kwarc.info/projects/krextor/genuri"
               xmlns:xs="http://www.w3.org/2001/XMLSchema"
                      exclude-result-prefixes="">
                      
<!--  CAEXFile -->

<!--<xsl:param name="autogenerate-fragment-uris" select="'generate-id'"/>-->

 <xsl:template match="/" mode="krextor:main">
      <xsl:apply-imports>
        <xsl:with-param
          name="krextor:base-uri"
          select="xs:anyURI('https://w3id.org/i40/aml/')"
          as="xs:anyURI"
          tunnel="yes"/>
      </xsl:apply-imports>
 </xsl:template>
    
<xsl:param name="autogenerate-fragment-uris" select="'pseudo-xpath'" />

 
 
<xsl:variable name="krextor:resources">
	<CAEXFile type="&aml;CAEXFile"/>
	<AdditionalInformation type="&aml;AdditionalInformation" related-via-properties="&aml;hasAdditionalInfomation"/>
	
	<ExternalReference type="&aml;ExternalReference" related-via-properties="&aml;hasExternalReference"/>
	
	<InstanceHierarchy type="&aml;InstanceHierarchy" related-via-properties="&aml;hasInstanceHierarchy"/>
	
	<InterfaceClassLib type="&aml;InterfaceClassLib" related-via-properties="&aml;hasInterfaceClassLib"/>
	
	<RoleClassLib type="&aml;RoleClassLib" related-via-properties="&aml;hasRoleClassLib"/>
	
	<SystemUnitClassLib type="&aml;SystemUnitClassLib" related-via-properties="&aml;hasSystemUnitClassLib"/>
	
	<InternalElement type="&aml;InternalElement" related-via-properties="&aml;hasInternalElement"/>
	<Attribute type="&aml;Attribute" related-via-properties="&aml;hasAttribute"/>
	<RefSemantic type="&aml;RefSemantic" related-via-properties="&aml;hasRefSemantic"/>
	<ExternalInterface type="&aml;ExternalInterface" related-via-properties="&aml;hasExternalInterface"/>
	<SupportedRoleClass type="&aml;SupportedRoleClass" related-via-properties="&aml;hasSupportedRoleClass"/>
		
	<RoleRequirements type="&aml;RoleRequirements" related-via-properties="&aml;hasRoleRequirements"/> 
	<InterfaceClass type="&aml;InterfaceClass" related-via-properties="&aml;hasInterfaceClass"/>
	
	<SystemUnitClass type="&aml;SystemUnitClass" related-via-properties="&aml;hasSystemUnitClass"/>
	
	<RoleClass type="&aml;RoleClass" related-via-properties="&aml;hasRoleClass &aml;hasRoleClass"/>
</xsl:variable>

<xsl:template match="CAEXFile
					|CAEXFile/AdditionalInformation
					|CAEXFile/ExternalReference
					|CAEXFile/InstanceHierarchy
					|CAEXFile/RoleClassLib
					|CAEXFile/SystemUnitClassLib
					|CAEXFile/InstanceHierarchy/InternalElement
					|Attribute
					|RefSemantic
					|ExternalInterface
					|SupportedRoleClass
					|RoleRequirements
					|InterfaceClassLib
					|InterfaceClass
					|RoleClass
					|SystemUnitClass" mode="krextor:main">
	   <xsl:apply-templates select="." mode="krextor:create-resource"/>
</xsl:template>


<xsl:variable name="krextor:literal-properties">
	    <FileName property="&aml;hasFileName" krextor:attribute="yes"/>
	    <SchemaVersion property="&aml;hasSchemaVersion" krextor:attribute="yes"/>	    
<!-- AdditionalInformation -->
	    <WriterName property="&aml;hasWriterName"/>
	    <WriterID property="&aml;hasWriterID" datatype="&xsd;string" />
	    <WriterVendor property="&aml;hasWriterVendor" datatype="&xsd;string" />
	    <WriterVendorURL property="&aml;hasWriterVendorURL" datatype="&xsd;string" />
	    <WriterVersion property="&aml;hasWriterVersion" datatype="&xsd;string" />
	    <WriterRelease property="&aml;hasWriterRelease" datatype="&xsd;string" />
	    <LastWritingDateTime property="&aml;hasLastWritingDateTime" datatype="&xsd;dateTime" />
	    <WriterProjectTitle property="&aml;hasWriterProjectTitle" datatype="&xsd;string" />
	    <WriterProjectID property="&aml;hasWriterProjectID" datatype="&xsd;string" />
<!-- ExternalReference -->
	    <Path property="&aml;refBaseClassPath" krextor:attribute="yes" datatype="&xsd;string"/>
	    <Alias property="&aml;externalReferenceAlias" krextor:attribute="yes" datatype="&xsd;string"/>	
<!-- InstanceHierarchy  -->
<!--		<Name property="&schema;name" krextor:attribute="yes" datatype="&xsd;string"/>-->
		
<!-- Attribute  -->
		<AttributeDataType property="&aml;hasDataType" krextor:attribute="yes" datatype="&xsd;string"/>
		<Description property="&aml;hasDescription" krextor:attribute="yes" datatype="&xsd;string"/>
		<Value property="&aml;hasAttributeValue" krextor:attribute="yes" datatype="&xsd;string"/>
		<Name property="&aml;hasAttributeName" krextor:attribute="yes" datatype="&xsd;string"/>

<!-- InternalElement -->
		<ID property="&dc;identifier" krextor:attribute="yes" datatype="&xsd;string"/>
		<RefBaseSystemUnitPath property="&aml;RefBaseSystemUnitPath" krextor:attribute="yes" datatype="&xsd;string"/>
<!-- ExternalInterface -->
		<RefBaseClassPath property="&aml;refBaseClassPath" krextor:attribute="yes" datatype="&xsd;string"/>
<!-- SupportedRoleClass -->
		<RefRoleClassPath property="&aml;refRoleClassPath" krextor:attribute="yes" datatype="&xsd;string"/>
<!-- RoleRequirements -->
		<RefBaseRoleClassPath property="&aml;refBaseRoleClassPath" krextor:attribute="yes" datatype="&xsd;string"/>
<!-- InterfaceClassLib -->
		<Version property="&aml;hasVersion" datatype="&xsd;string" />
<!-- <InterfaceClass property="&aml;hasInterfaceClass" object-is-list="true" /> -->

<!-- the following mapping rules will be simplified in the second example, this version can be treated as standard test case -->
</xsl:variable>
<xsl:template match="CAEXFile/@FileName
                      |CAEXFile/@SchemaVersion
                      |CAEXFile/AdditionalInformation/WriterHeader/WriterName
	                  |CAEXFile/AdditionalInformation/WriterHeader/WriterID
                      |CAEXFile/AdditionalInformation/WriterHeader/WriterVendor
	                  |CAEXFile/AdditionalInformation/WriterHeader/WriterVendorURL
	                  |CAEXFile/AdditionalInformation/WriterHeader/WriterVersion
	                  |CAEXFile/AdditionalInformation/WriterHeader/WriterRelease
	                  |CAEXFile/AdditionalInformation/WriterHeader/LastWritingDateTime
	                  |CAEXFile/AdditionalInformation/WriterHeader/WriterProjectTitle
	                  |CAEXFile/AdditionalInformation/WriterHeader/WriterProjectID
	                  |CAEXFile/ExternalReference/@Path
	                  |CAEXFile/ExternalReference/@Alias
	                  |CAEXFile/InstanceHierarchy/@Name
	                  |CAEXFile/InstanceHierarchy/InternalElement/@Name
	                  |CAEXFile/InstanceHierarchy/InternalElement/@ID
	                  |CAEXFile/InstanceHierarchy/InternalElement/@RefBaseSystemUnitPath
	                  |CAEXFile/InstanceHierarchy/InternalElement/Attribute/@Name
	                  |CAEXFile/InstanceHierarchy/InternalElement/ExternalInterface/@Name
	                  |CAEXFile/InstanceHierarchy/InternalElement/ExternalInterface/@ID
	                  |CAEXFile/InstanceHierarchy/InternalElement/ExternalInterface/@RefBaseClassPath
	                  |CAEXFile/InstanceHierarchy/InternalElement/SupportedRoleClass/@RefRoleClassPath
	                  |CAEXFile/InstanceHierarchy/InternalElement/RoleRequirements/@RefBaseRoleClassPath
	                  |CAEXFile/InterfaceClassLib/@Name
	                  |CAEXFile/InterfaceClassLib/InterfaceClass/@Name
	                  |CAEXFile/InterfaceClassLib/InterfaceClass/@RefBaseClassPath
	                  |CAEXFile/RoleClassLib/@Name
	                  |CAEXFile/RoleClassLib/Version
	                  |CAEXFile/RoleClassLib/RoleClass/@Name
					  |CAEXFile/RoleClassLib/RoleClass/Attribute/@Name
					  |CAEXFile/RoleClassLib/RoleClass/Attribute/Value
	                  |CAEXFile/RoleClassLib/RoleClass/@RefBaseClassPath
	                  |CAEXFile/SystemUnitClassLib/@Name
	                  |CAEXFile/SystemUnitClassLib/Version
	                  |CAEXFile/SystemUnitClassLib/SystemUnitClass/@Name
	                  |CAEXFile/SystemUnitClassLib/SystemUnitClass/ExternalInterface/@Name
	                  |CAEXFile/SystemUnitClassLib/SystemUnitClass/ExternalInterface/@ID
	                  |CAEXFile/SystemUnitClassLib/SystemUnitClass/ExternalInterface/@RefBaseClassPath
	                  |CAEXFile/SystemUnitClassLib/SystemUnitClass/SupportedRoleClass/@RefRoleClassPath" 
	                  mode="krextor:main">
 <xsl:apply-templates select="." mode="krextor:add-literal-property"/>
</xsl:template>


<xsl:template match="CAEXFile/AdditionalInformation/@AutomationMLVersion" mode="krextor:main">
  <xsl:call-template name="krextor:add-literal-property">
    <xsl:with-param name="property" select="'&aml;hasAutomationMLVersion'"/>
    <xsl:with-param name="datatype " select="'&xsd;string'"/>
  </xsl:call-template>
</xsl:template>

<xsl:template match="//RefSemantic/@CorrespondingAttributePath" mode="krextor:main">
  <xsl:call-template name="krextor:add-literal-property">
    <xsl:with-param name="property" select="'&aml;hasCorrespondingAttributePath'"/>
    <xsl:with-param name="datatype " select="'&xsd;string'"/>
  </xsl:call-template>
</xsl:template>

<xsl:template match="//Attribute/@Value" mode="krextor:main">
  <xsl:call-template name="krextor:add-literal-property">
    <xsl:with-param name="property" select="'&aml;hasAttributeValue'"/>
    <xsl:with-param name="datatype " select="'&xsd;string'"/>
  </xsl:call-template>
</xsl:template>


</xsl:transform>