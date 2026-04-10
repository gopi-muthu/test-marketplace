// -------------------------------------------------------------------------------
// © 2026 Intergraph Corporation and/or its subsidiaries and affiliates. All rights reserved.
// -------------------------------------------------------------------------------

using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace <Namespace>.Tests
{
    /// <summary>
    ///
    /// </summary>
    [TestClass]
    public class AssemblyResolvingTestInitializer
    {
        /// <summary>
        ///
        /// </summary>
        /// <param name="context"></param>
        [AssemblyInitialize]
        public static void AssemblyInit(TestContext context)
        {
            string[] args =
            {
                @"G:\Mroot\CommonApp\SOM\Middle\CommonMiddle\CommonMiddle\CommonMiddle.csproj",
                @"G:\Mroot\RefData\SOM\Middle\BusinessObject\ReferenceDataMiddle.csproj",
                @"G:\Mroot\CommonApp\SOM\Client\CommonClient\CommonClient\CommonClient.csproj",
                @"<RootPath>\<Component><ProjectSuffix>\<Component><ProjectSuffix>\<Component><ProjectSuffix>.csproj",
                @"<RootPath>\<Component><ProjectSuffix>\<Component><ProjectSuffix>Tests\<Component><ProjectSuffix>Tests.csproj"
            };
            var unitTestAssemblyResolver = new CommonNetCoreUnitTests.BaseUnitTestAssemblyResolver(args);
            AppDomain.CurrentDomain.AssemblyResolve += unitTestAssemblyResolver.OnAssemblyResolve;
        }
    }
}
