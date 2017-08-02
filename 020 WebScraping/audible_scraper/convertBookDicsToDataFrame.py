import numpy as np
import pandas as pd
import re


def convertBookDicsListToDataFrame(bookDics):

    def flattenBreadcrumds(b):
        result = b.copy()
        result.pop("breadcrumbs")
        bc = b["breadcrumbs"]
        if len(bc)>1:
            result["category"] = bc[1]
        else:
            result["category"] = None
        if len(bc)>2:
            result["subcategory"] = bc[2]
        else:
            result["subcategory"] = None
        return result

    bd01 = list(map(flattenBreadcrumds, bookDics))

    bs_df = pd.DataFrame(bd01)
    bs_df["adbl.rating.overall.count"] = list(map(lambda x: int(x.replace("(", "").replace(")", "").strip()) if not x is None else None, bs_df["adbl.rating.overall.count"]))
    bs_df["adbl.rating.overall.value"] = list(map(lambda x: float(x) if not x is None else None, bs_df["adbl.rating.overall.value"]))
    bs_df["adbl.rating.performance.count"] = list(map(lambda x: int(x.replace("(", "").replace(")", "").strip()) if not x is None else None, bs_df["adbl.rating.performance.count"]))
    bs_df["adbl.rating.performance.value"] = list(map(lambda x: float(x) if not x is None else None, bs_df["adbl.rating.performance.value"]))
    bs_df["adbl.rating.story.count"] = list(map(lambda x: int(x.replace("(", "").replace(")", "").strip()) if not x is None else None, bs_df["adbl.rating.story.count"]))
    bs_df["adbl.rating.story.value"] = list(map(lambda x: float(x) if not x is None else None, bs_df["adbl.rating.story.value"]))
    bs_df["amazon.rating.overall.count"] = list(map(lambda x: float(x.replace("(", "").replace(" customer reviews)", "").replace(" customer review)", "").replace(",", "").strip()) if not x is None else None, bs_df["amazon.rating.overall.count"]))
    bs_df["amazon.rating.overall.value"] = list(map(lambda x: float(x.replace(" out of 5 stars", "").strip()) if not x is None else None, bs_df["amazon.rating.overall.value"]))
    bs_df["authors"] = list(map(lambda x: x.strip() if not x is None else None, bs_df["authors"]))
    bs_df["category"] = list(map(lambda x: x.strip() if not x is None else None, bs_df["category"]))

    def lengthStringToMinutes(s):
        if s is None:
            return None
        result = 0
        
        m = re.search("([0-9]+) hrs",s)
        if not m is None:
            result = int(m.group(1))*60

        m = re.search("([0-9]+) mins",s)
        if not m is None:
            result += int(m.group(1))    
        if result == 0:
            result = None
        return result

    bs_df["length"] = list(map(lengthStringToMinutes, bs_df["length"]))

    bs_df["narrated_by"] = list(map(lambda x: x.strip() if not x is None else None, bs_df["narrated_by"]))
    bs_df["price"] = list(map(lambda x: float(x.replace("$", "").strip()) if not x is None else None, bs_df["price"]))
    bs_df["program_format"] = list(map(lambda x: x.strip() if not x is None else None, bs_df["program_format"]))
    bs_df["publisher"] = list(map(lambda x: x.strip() if not x is None else None, bs_df["publisher"]))
    bs_df["release_date"] = list(map(lambda x: pd.to_datetime(x.strip()) if not x is None else None, bs_df["release_date"]))
    bs_df["series"] = list(map(lambda x: x.strip() if not x is None else None, bs_df["series"]))
    bs_df["subcategory"] = list(map(lambda x: x.strip() if not x is None else None, bs_df["subcategory"]))
    bs_df["title"] = list(map(lambda x: x.strip() if not x is None else None, bs_df["title"]))
    
    return bs_df

filenName = "bestsellers_2017-08-02"
bookDics = np.load(filenName + '.npy')
df = convertBookDicsListToDataFrame(bookDics)
print(df)
df.to_csv(filenName + '.csv')

