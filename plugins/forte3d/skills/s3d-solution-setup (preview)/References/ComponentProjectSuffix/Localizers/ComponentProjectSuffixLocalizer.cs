// -----------------------------------------------------------------------------
//       Copyright (C) 2026, Intergraph Corporation and/or its subsidiaries and affiliates. All rights reserved.
// -----------------------------------------------------------------------------
using System;
using System.Runtime.CompilerServices;
using System.Text;

namespace <NameSpace>.i18n
{
    public class <Component><ProjectSuffix>Localizer
    {
        #region Singleton Static Infrastructure

        /// <summary>
        /// CommandingViewRes instance (singleton)
        /// </summary>
        private static <Component><ProjectSuffix>Localizer _instance;

        /// <summary>
        /// GetInstance:  required for XAML ObjectDataProvider
        /// </summary>
        public static <Component><ProjectSuffix>Localizer GetInstance()
        {
            return _instance ?? (_instance = new <Component><ProjectSuffix>Localizer());
        }

        /// <summary>
        /// Constructor
        /// </summary>
        private <Component><ProjectSuffix>Localizer() { }

        #endregion

        #region GetString
        /// <summary>
        /// This method is used to set the localized strings for control's text and error messages.
        /// If the string matches with the string in resource file, appropriate message from resource file is fetched else the default message.
        /// </summary>
        internal string GetString(string defaultMessage, [CallerMemberName] string id = "")
        {
            return Common.Middle.Services.CmnLocalizer.GetString(id, defaultMessage, "<NameSpace>.Resources.<Component><ProjectSuffix>", "<Component><ProjectSuffix>");
        }
        #endregion
    }
}
